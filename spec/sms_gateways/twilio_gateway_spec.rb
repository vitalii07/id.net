require 'spec_helper'

describe TwilioGateway do
  before do
    allow(Idnet.config.application).to receive(:send_sms).and_return(true)
    allow(Idnet.config.sms.twilio).to receive(:account_sid).and_return('123456')
    allow(Idnet.config.sms.twilio).to receive(:auth_token).and_return('alongtokenstring')
  end

  # for result codes see lib
  def stub_response(code)
    exception = ::Twilio::REST::RequestError.new('foo', code)
    allow_any_instance_of(Twilio::REST::Messages).to receive(:create).and_raise(exception)
  end

  describe "#send_message" do
    describe "with error codes" do
      it "raises InsufficientFundsError" do
        stub_response(10001)
        expect {
          subject.send_message(1, 2)
        }.to raise_error(Idnet::Core::MobileGateway::InsufficientFundsError)
      end

      it "raises RecipientError" do
        stub_response(21612)
        expect {
          subject.send_message(1, 2)
        }.to raise_error(Idnet::Core::MobileGateway::RecipientError)
      end

      it "raises GatewayInternalError" do
        stub_response(12400)
        expect {
          subject.send_message(1, 2)
        }.to raise_error(Idnet::Core::MobileGateway::GatewayInternalError)
      end

      it "raises NetworkError" do
        Idnet::Core::MobileGateway::NETWORK_EXCEPTIONS.each do |exception|
          allow_any_instance_of(Twilio::REST::Messages).to receive(:create).and_raise(exception)
          expect {
            subject.send_message(1, 2)
          }.to raise_error(Idnet::Core::MobileGateway::NetworkError)
        end
      end

      it "raises AnotherError with unhandled code" do
        stub_response(1)
        expect {
          subject.send_message(1, 2)
        }.to raise_error(Idnet::Core::MobileGateway::AnotherError)
      end
    end
  end
end
