require 'spec_helper'

describe CertificationsHelper do

  context 'country code' do
    shared_examples_for 'set from ip' do |ip, code|
      before do
        $geoip = GeoIP.new("lib/extras/geoip.dat")
      end

      it "should set country code" do
        allow(controller.request).to receive(:remote_ip).and_return(ip)
        helper.default_prefix.should eq(code)
      end
    end

    # Google USA
    it_should_behave_like 'set from ip', '8.8.8.8', '1'
    # Oleane France
    it_should_behave_like 'set from ip', '194.2.0.20', '33'
    # Kiev kz.net.ua Ukraine
    it_should_behave_like 'set from ip', '91.212.56.5', '380'
    # Yandex Russia
    it_should_behave_like 'set from ip', '77.88.8.8', '7'

  end

  context 'mobile number' do
    it 'should parse correct mobile number' do
      correct_mobile_number = '+380637859498'
      helper.global_phone_parse(correct_mobile_number, :country_code).should == '380'
      helper.global_phone_parse(correct_mobile_number, :national_string).should == '637859498'
    end

    shared_examples_for 'wrong number' do |code|
      it 'should return nil' do
        helper.global_phone_parse(code, :country_code).should be_nil
        helper.global_phone_parse(code, :national_string).should be_nil
      end
    end

    it_should_behave_like 'wrong number', '+123321123'
    it_should_behave_like 'wrong number', nil
    it_should_behave_like 'wrong number', 'wrong *7^ numb'
  end

end
