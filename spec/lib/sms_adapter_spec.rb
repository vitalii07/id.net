require 'spec_helper'

describe Idnet::Core::SmsAdapter do
  subject { Idnet::Core::SmsAdapter }

  let(:record) do
    double.tap do |m|
      allow(m).to receive(:id).and_return 1
      allow(m).to receive(:number).and_return "123456789"
      allow(m).to receive(:message).and_return "message"
    end
  end
  Gate1 = Class.new
  Gate2 = Class.new
  Gate3 = Class.new

  before do
    Rails.application.config.sms_adapter = {}
  end

  describe "configuration" do
    describe "#register" do
      it "adds gateway" do
        expect {
          subject.configure { |config| config.register :foo, Class }
          subject.configure { |config| config.register :bar, Class }
        }.to change { subject.config.gateways }
      end

      it "rejects duplicated names" do
        subject.configure { |config| config.register :foo, Class }
        expect {
          subject.configure { |config| config.register :foo, Class }
        }.to raise_error
      end
    end

    describe "#default_gateway=" do
      it "sets default gateway" do
        subject.configure { |config| config.register :foo, Class }
        expect {
          subject.configure { |config| config.default_gateway = :foo }
        }.to change { subject.config.default_gateway }.to(:foo)
      end

      it "rejects default gateway which is not in gateways" do
        subject.configure { |config| config.register :foo, Class }
        expect {
          subject.configure { |config| config.default_gateway = :bar }
        }.to raise_error
      end
    end
  end

  describe "#send_message" do
    before do
      subject.configure do |config|
        config.register :gate1, Gate1
        config.default_gateway = :gate1
      end
    end

    it "sends message through sms gateway" do
      expect_any_instance_of(Gate1).to receive(:send_message)
      subject.new(record).send_message(:number, :message)
    end

    it "should not send message with empty trust code" do
      expect_any_instance_of(Gate1).to_not receive(:send_message)
      allow(record).to receive(:sms_trust_code).and_return nil
      subject.new(record).send_message(:number, :sms_trust_message)
    end
  end

  describe "#switch_gateway!" do
    it "cycles through gateways" do
      subject.configure do |config|
        config.register :gate1, Gate1
        config.register :gate2, Gate2
        config.register :gate3, Gate3
        config.default_gateway = :gate1
      end

      expect_any_instance_of(subject).to receive(:stored_gateway_name).and_return nil # don't care what's in redis DB
      adapter = subject.new(record)
      adapter.gateway.should be_a(Gate1)

      allow(adapter).to receive(:stored_gateway_name).and_return(:gate1)
      adapter.switch_gateway!
      adapter.gateway.should be_a(Gate2)

      allow(adapter).to receive(:stored_gateway_name).and_return(:gate2)
      adapter.switch_gateway!
      adapter.gateway.should be_a(Gate3)

      allow(adapter).to receive(:stored_gateway_name).and_return(:gate3)
      adapter.switch_gateway!
      adapter.gateway.should be_a(Gate1)
    end
  end
end
