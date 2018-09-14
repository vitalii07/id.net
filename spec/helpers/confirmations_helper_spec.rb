require 'spec_helper'

describe ConfirmationsHelper do
  describe "#secret_mobile" do
    it "skips incorrect mobile" do
      secret_mobile(nil).should == nil
      secret_mobile("foo").should == "foo"
    end

    it "hides mobile number" do
      secret_mobile("+13125551212").should == "+********212"
    end
  end

  describe "#secret_email" do
    it "skips incorrect email" do
      secret_email("foobar").should == "foobar"
    end

    it "hides email" do
      secret_email("foo@test.com").should == "f**@test.com"
    end
  end
end
