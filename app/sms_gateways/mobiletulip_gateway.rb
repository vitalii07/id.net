require 'mollie/sms'

# ID-474: mobiletulip changed url
if Mollie::SMS.const_defined?('GATEWAY_URI')
  Mollie::SMS.send(:remove_const, 'GATEWAY_URI')
end
Mollie::SMS.const_set "GATEWAY_URI", URI.parse("http://api.mobiletulip.com/xml/sms")
class Mollie::SMS
  # Posts the {#params parameters} to the gateway, without SSL
  #
  # The params are validated before attempting to post them.
  # @see #validate_params!
  #
  # @return [Response] A response object which encapsulates the result of the
  #                    request.
  def deliver
    validate_params!

    post = Net::HTTP::Post.new(GATEWAY_URI.path)
    post.form_data = params
    request = Net::HTTP.new(GATEWAY_URI.host, GATEWAY_URI.port)
    # request.use_ssl = true
    # request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request.start do |http|
      response = http.request(post)
      Response.new(response)
    end
  end

end


class MobiletulipGateway < Idnet::Core::MobileGateway
  def initialize
    raise SmsDisabledError unless Idnet.config.application.send_sms

    Mollie::SMS.gateway = Idnet.config.sms.mollie.gateway
    Mollie::SMS.username = Idnet.config.sms.mollie.username
    Mollie::SMS.password = Idnet.config.sms.mollie.password
    Mollie::SMS.originator = Idnet.config.sms.sender
  end

  def send_message(number, message)
    sms = Mollie::SMS.new(number, message)
    sms.deliver!
  rescue ::Mollie::SMS::Exceptions::DeliveryFailure => e
    # NOTE: error codes described in http://www.mollie.nl/support/documentatie/sms-diensten/sms/http/en/
    code = e.response.result_code
    case code
    when 31                     # "not enough credits to send message"
      raise InsufficientFundsError.new(code)
    when 23,                    # "no 'recipients'"
         25                     # "incorrect 'recipients'"
      raise RecipientError.new(code)
    when 98,                    # "gateway unreachable"
         99                     # "unknown error"
      raise GatewayInternalError.new(code)
    else
      raise AnotherError.new(code, e.class)
    end
  rescue *NETWORK_EXCEPTIONS
    raise NetworkError
  end
end
