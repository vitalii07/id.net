require 'spec_helper'
require 'gateway_decisioner'

describe GatewayDecisioner do
  let!(:csv) {%q{
JPN,100,mobiletulip
JPN,25,twilio
DEFAULT,5,mobiletulip
DEFAULT,5,twilio
DEFAULT,5,clickatell
}}

  subject { GatewayDecisioner.new csv }

  describe "#run" do
    describe "uses country rules" do
      it do
        allow(subject).to receive(:random_weight).and_return(10)
        subject.run("JPN").should == 'mobiletulip'
      end

      it do
        allow(subject).to receive(:random_weight).and_return(110)
        subject.run("JPN").should == 'twilio'
      end
    end

    describe "uses default rules" do
      it do
        allow(subject).to receive(:random_weight).and_return(3)
        subject.run("foo").should == 'mobiletulip'
      end

      it do
        allow(subject).to receive(:random_weight).and_return(7)
        subject.run("foo").should == 'twilio'
      end

      it do
        allow(subject).to receive(:random_weight).and_return(14)
        subject.run("foo").should == 'clickatell'
      end
    end
  end

end
