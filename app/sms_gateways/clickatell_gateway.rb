require 'clickatell'

class ClickatellGateway < Idnet::Core::MobileGateway

  class UnroutableError < GatewayError
    def initialize(code, number)
      message = "Code #{code}: can not route message to #{number}. Please contact clickatell support"
      super(code, message)
    end
  end

  def initialize
    raise SmsDisabledError unless Idnet.config.application.send_sms

    config = Idnet.config.sms.clickatell
    @sender = Clickatell.new config.user, config.password, config.api_id
  end

  def send_message(number, message)
    @sender.sms number.gsub('+',''), message
  rescue Clickatell::RemoteError => e
    # NOTE for error codes see https://jira.helios.me/secure/attachment/12649/Clickatell_HTTP.pdf, page 32
    case e.code
    when 301                    # No credit left
      raise InsufficientFundsError.new(e.code)
    when 114                    # Cannot route message
      raise UnroutableError.new(e.code, number)
    when 105                    # Invalid destination address
      raise RecipientError.new(e.code)
    when 901                    # Internal error
      raise GatewayInternalError.new(e.code)
    else
      raise AnotherError.new(e.code, e.class)
    end
  rescue *NETWORK_EXCEPTIONS
    raise NetworkError
  end
end
