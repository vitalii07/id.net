require 'spec_helper'

describe 'legacy routing' do
  include Warden::Test::Helpers
  Warden.test_mode!
  let(:account){ create :confirmed_account }

  describe "profiles routes", type: :request do
    it "should redirect profiles#edit to redirects#edit_identity_by_pid" do
      expect(get: "/profiles/123456/edit").to be_routable
      expect(get: "/profiles/123456/edit").to route_to controller: 'redirects', action: 'edit_identity_by_pid', id: '123456'
    end

    it "should redirect profiles#edit to redirects#edit_identity_by_site" do
      expect(get: "/profiles/123456/edit").to be_routable
      expect(get: "/sites/123456").to route_to controller: 'redirects', action: 'edit_identity_by_site', id: '123456'
    end

  end

  describe 'certifications routes', type: :request do
    before { login_as(account, :scope => :account) }
    it 'should redirect old route' do
      get '/certifications'
      response.should redirect_to(root_certification_path)
    end
  end
end
