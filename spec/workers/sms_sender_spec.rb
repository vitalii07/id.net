require 'spec_helper'

describe SmsSender do
  let!(:account) { create :account }

  def stub_exception(exception)
    allow_any_instance_of(Account).to receive(:sms_adapter).and_raise(exception)
  end

  describe "self.perform" do
    describe "on insufficient credits" do
      let(:deliverer) { double(:deliverer) }
      it "sends mail and creates notification" do
        stub_exception(Idnet::Core::MobileGateway::InsufficientFundsError)
        expect(deliverer).to receive(:deliver_now)
        expect(FailureMailer).to receive(:mollie_insufficient_funds).and_return(deliverer)
        expect {
          SmsSender.perform(account.id, "methodname", "+123456789")
        }.to change { account.reload.notifications.count }.by(1)
      end
    end

    describe "on recipients errors" do
      it "creates notification" do
        stub_exception(Idnet::Core::MobileGateway::RecipientError)
        expect {
          SmsSender.perform(account.id, "methodname", "+123456789")
        }.to change { account.reload.notifications.count }.by(1)
      end
    end

    describe "on gateway errors" do
      before { stub_exception(Idnet::Core::MobileGateway::GatewayInternalError) }

      it "retries" do
        expect(SmsSender).to receive(:retry_send).and_return(true)
        SmsSender.perform(account.id, "methodname", "+123456789")
      end

      it "reraises if retry failed" do
        expect(SmsSender).to receive(:retry_send).and_return(false)
        expect {
          SmsSender.perform(account.id, "methodname", "+123456789")
        }.to raise_error
      end
    end

    describe "on network errors" do
      before { stub_exception(Idnet::Core::MobileGateway::NetworkError) }

      it "retries" do
        expect(SmsSender).to receive(:retry_send).and_return(true)
        SmsSender.perform(account.id, "methodname", "+123456789")
      end

      it "reraises if retry failed" do
        expect(SmsSender).to receive(:retry_send).and_return(false)
        expect {
          SmsSender.perform(account.id, "methodname", "+123456789")
        }.to raise_error
      end
    end
  end

  describe "self.retry_send" do
    it "enqueues job once" do
      allow(Resque.redis).to receive(:exists).and_return(false)
      expect(Resque).to receive(:enqueue_in)
      SmsSender.retry_send.should_not == false
    end

    it "does nothing if job was already enqueued" do
      allow(Resque.redis).to receive(:exists).and_return(true)
      SmsSender.retry_send.should == false
    end
  end
end
