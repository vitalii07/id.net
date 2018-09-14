require 'spec_helper'

# Need to hook into routes because assert_recognizes is discarding extra params
describe 'OAuth 2.0 routing' do
  it 'routes /oauth/grant to oauth2#token' do
    expected = @routes.recognize_path('/oauth/grant', method: :post)
    expected.should == {controller: 'oauth2', action: 'grant'}
  end
end

describe 'OAuth 2.0 SDK routing' do
  context 'GET' do
    it 'routes /oauth/grant to oauth2_sdk#grant' do
      expected = @routes.recognize_path('/oauth/grant?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'grant'}
    end

    it 'routes /oauth/deny to oauth2_sdk#deny' do
      expected = @routes.recognize_path('/oauth/deny?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'deny'}
    end

    it 'routes /oauth/authorize to oauth2_sdk#authorize' do
      expected = @routes.recognize_path('/oauth/authorize?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'authorize'}
    end

    it 'routes /oauth/choose_identity to oauth2_sdk#choose_identity' do
      expected = @routes.recognize_path('/oauth/choose_identity?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'choose_identity'}
    end

    it 'routes /oauth/new_identity to oauth2_sdk#new_identity' do
      expected = @routes.recognize_path('/oauth/new_identity?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'new_identity'}
    end

    it 'routes /oauth/refresh_identity to oauth2_sdk#refresh_identity' do
      expected = @routes.recognize_path('/oauth/refresh_identity?_sdk=1', method: :get)
      expected.should == {controller: 'oauth2_sdk', action: 'refresh_identity'}
    end

  end

  context 'POST' do
    it 'routes /oauth/grant to oauth2_sdk#grant' do
      expected = @routes.recognize_path('/oauth/grant?_sdk=1', method: :post)
      expected.should == {controller: 'oauth2_sdk', action: 'grant'}
    end

    it 'routes /oauth/deny to oauth2_sdk#deny' do
      expected = @routes.recognize_path('/oauth/deny?_sdk=1', method: :post)
      expected.should == {controller: 'oauth2_sdk', action: 'deny'}
    end

    it 'routes /oauth/grant_or_deny to oauth2_sdk#grant_or_deny' do
      expected = @routes.recognize_path('/oauth/grant_or_deny?_sdk=1', method: :post)
      expected.should == {controller: 'oauth2_sdk', action: 'grant_or_deny'}
    end

    it 'routes /oauth/refresh_identity to oauth2_sdk#refresh_identity' do
      expected = @routes.recognize_path('/oauth/refresh_identity?_sdk=1', method: :post)
      expected.should == {controller: 'oauth2_sdk', action: 'refresh_identity'}
    end

  end

end
