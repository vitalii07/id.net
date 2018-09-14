require 'twilio-ruby'

class TwilioGateway < Idnet::Core::MobileGateway
  # need error code in errbit messages
  class ::Twilio::REST::RequestError
    def initialize(message, code=nil)
      super "#{code}: #{message}"
      @code = code
    end
  end

  RECIPIENT_ERROR_CODES = [
    # all of these need to be checked in production
    # 14101, # "To" Attribute is Invalid
    # 21201, # No 'To' number specified
    # 21214, # 'To' phone number cannot be reached
    # 21217, # Phone number does not appear to be valid
    # 21610, # SMS cannot be sent to the 'To' number because the customer has replied with STOP
    # 21618, # The message body cannot be sent
    # real errors from errbit
    21211, # Invalid 'To' Phone Number
    21612, # The 'To' phone number is not currently reachable via SMS
    21614, # 'To' number is not a valid mobile number (NOTE: can also happen to valid numbers passing GlobalPhone validation)
    21408, # Permission to send an SMS has not been enabled for the region indicated by the 'To' number
    21604, # 'To' phone number is required to send an SMS
  ]

  def initialize
    raise SmsDisabledError unless Idnet.config.application.send_sms

    account_sid = Idnet.config.sms.twilio.account_sid
    auth_token = Idnet.config.sms.twilio.auth_token
    @client = Twilio::REST::Client.new account_sid, auth_token
  end

  def send_message(number, message)
    @client.account.sms.messages.create(
      from: Idnet.config.sms.twilio.from,
      to: number,
      body: message)
  rescue Twilio::REST::RequestError => e
    # NOTE: error codes described in http://www.twilio.com/docs/errors/reference
    case e.code
    when 10001                  # "Account is not active" - account is blocked when there's not enough funds
      raise InsufficientFundsError.new(e.code)
    when *RECIPIENT_ERROR_CODES
      raise RecipientError.new(e.code)
    when 12400                  # "Internal Failure"
      raise GatewayInternalError.new(e.code)
    else
      raise AnotherError.new(e.code, e.class)
    end
  rescue *NETWORK_EXCEPTIONS
    raise NetworkError
  end
end
