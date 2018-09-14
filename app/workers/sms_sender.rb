# NOTE this code uses resque-scheduler to retry sending sms one time.
# If you want to repeat it more than one time, consider using
# resque-retry or add simple implementation of retry using counter in
# redis (Resque.redis)
require 'resque-scheduler'

class SmsSender
  @queue = :sms_confirmation
  RETRY_TIMEOUT = 2.minutes

  def self.retry_send(*args)
    account_id, number_method, message_method = args
    key = "idnet:sms:#{account_id}"

    if Resque.redis.exists(key)
      Resque.redis.del(key)
      return false
    else
      Resque.redis.incr(key)
      Resque.enqueue_in(RETRY_TIMEOUT, SmsSender, *args)
    end
  end

  def self.perform(*args)
    account_id, number_method, message_method, data = args

    account = Account.find(account_id)
    return unless account

    begin
      account.sms_adapter.sync_send_message number_method, message_method, data
    rescue Idnet::Core::MobileGateway::InsufficientFundsError
      # CHECK
      # Not sure if we need asynchronous delivery here
      # FailureMailer.delay(queue: 'idnet_mailer').mollie_insufficient_funds
      FailureMailer.mollie_insufficient_funds.deliver_now
      account.notifications.create(notification_type: "sms", message: I18n.t("workers.sms_sender.service_unavailable"))
    rescue Idnet::Core::MobileGateway::RecipientError
      account.notifications.create(notification_type: "sms", message: I18n.t("workers.sms_sender.recipient_incorrect"))
    rescue Idnet::Core::MobileGateway::GatewayInternalError, Idnet::Core::MobileGateway::NetworkError
      retry_send(args) || raise
    rescue => e
      Rails.logger.error("Failed to send sms: #{e}")
      raise
    end
  end
end
