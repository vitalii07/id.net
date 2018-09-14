require 'spec_helper'

describe Clickatell do
  subject { Clickatell.new 'user', 'password', 'api_id' }

  describe "#initialize" do
    it "uses POST by default" do
      subject.http_method.should == "post"
    end

    it "uses SSL by default" do
      subject.ssl.should == true
    end
  end

  describe "API methods" do
    describe "#auth" do
      it "runs 'auth' request" do
        expect(subject).to receive(:run).with("auth", anything).and_return("")
        subject.auth
      end

      it "returns authentication token" do
        allow(subject).to receive(:run).and_return("OK: token")
        subject.auth.should == "token"
      end
    end

    describe "#sms" do
      it "runs 'sendmsg' request" do
        expect(subject).to receive(:run).with("sendmsg", anything).and_return("ID: msgid")
        subject.sms 'number', 'text'
      end

      it "returns msgid" do
        allow(subject).to receive(:run).and_return("ID: msgid")
        subject.sms("number", "text").should == "msgid"
      end

      it "checks phone format" do
        expect {
          subject.sms("+123456789", "text")
        }.to raise_error
      end
    end

    describe "#query" do
      it "runs 'querymsg' request" do
        expect(subject).to receive(:run).with("querymsg", anything).and_return("ID: 123456abcdef Status: 001")
        subject.query 'msgid'
      end

      it "returns status code" do
        expect(subject).to receive(:run).and_return("ID: 123456abcdef Status: 001")
        subject.query("msgid").should == 1
      end
    end

    describe "#ping" do
      it "runs 'ping' request" do
        expect(subject).to receive(:run).with("ping")
        subject.ping
      end
    end

    describe "#delete" do
      it "runs 'delmsg' request" do
        expect(subject).to receive(:run).with("delmsg", anything).and_return("ID: 123456abcdef Status: 001")
        subject.delete 'msgid'
      end

      it "returns status code" do
        expect(subject).to receive(:run).and_return("ID: 123456abcdef Status: 001")
        subject.delete("msgid").should == 1
      end
    end

    describe "#balance" do
      it "runs 'getbalance' request" do
        expect(subject).to receive(:run).with("getbalance").and_return("Credit: 123.456")
        subject.balance
      end

      it "returns remaining balance" do
        expect(subject).to receive(:run).and_return("Credit: 123.456")
        subject.balance.should == 123.456
      end
    end
  end

  describe "#run" do
    it "raises RemoteError" do
      allow(subject).to receive(:http_method).and_return("post")
      allow(subject).to receive(:post).and_return("ERR: foobar")

      expect {
        subject.run("method")
      }.to raise_error { Clickatell::RemoteError }
    end
  end
end
