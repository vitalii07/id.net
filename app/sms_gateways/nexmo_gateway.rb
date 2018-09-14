require 'nexmo'

class NexmoGateway < Idnet::Core::MobileGateway

  def initialize
    raise SmsDisabledError unless Idnet.config.application.send_sms

    @nexmo = Nexmo::Client.new Idnet.config.sms.nexmo[:key], Idnet.config.sms.nexmo[:secret]
  end

  def send_message(number, message)
    response = @nexmo.send_message({to: number, from: Idnet.config.sms.nexmo.from, text: message})

    if response.ok? && response.json?
      response_messages = response.object['messages'].first

      status = response_messages['status'].to_i
      return if status == 0
      case status
      when 1, # Throttled You have exceeded the submission capacity allowed on this account, please back-off and retry
           8, # Partner account barred The api_key you supplied is for an account that has been barred from submitting messages
           9  # Partner quota exceeded Your pre-pay account does not have sufficient credit to process this message
        raise InsufficientFundsError.new(status, response_messages['error_text'])
      when 2, # Missing params Your request is incomplete and missing some mandatory parameters
           6, # Invalid message The Nexmo platform was unable to process this message, for example, an un-recognized number prefix
           7, # Number barred The number you are trying to submit to is blacklisted and may not receive messages
           14 # Invalid Signature Message was not submitted due to a verification failure in the submitted signature
        raise RecipientError.new(status, response_messages['error_text'])
      when 4, # Invalid credentials The api_key / api_secret you supplied is either invalid or disabled
           5, # Internal error An error has occurred in the Nexmo platform whilst processing this message
           10, # Too many existing binds The number of simultaneous connections to the platform exceeds the capabilities of your account
           13  # Communication Failed Message was not submitted because there was a communication failure
        raise GatewayInternalError.new(status, response_messages['error_text'])
      else #3 Invalid params The value of one or more parameters is invalid
           #11 Account not enabled for REST This account is not provisioned for REST submission, you should use SMPP instead
           #12 Message too long Applies to Binary submissions, where the length of the UDH and the message body combined exceed 140 octets
           #15 Invalid sender address The sender address (from parameter) was not allowed for this message. Restrictions may apply depending on the destination see our FAQs
           #16 Invalid TTL The ttl parameter values is invalid
           #19 Facility not allowed Your request makes use of a facility that is not enabled on your account
           #20  Invalid Message class The message class value su
        raise AnotherError.new(status, response_messages['error_text'])
      end
    end
  rescue *NETWORK_EXCEPTIONS
    raise NetworkError
  end
end