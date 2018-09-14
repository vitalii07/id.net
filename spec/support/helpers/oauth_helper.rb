module OAuthHelper
  extend ActiveSupport::Concern

  included do
    let(:redirect_uri) { 'http://example.com/callback' }
    let(:client) { create :client, redirect_uri: redirect_uri }

    let(:authorization) { create :authorization, :with_references, client: client }

    let(:auth) { authorization }
    let(:account) { authorization.account }
    let(:identity) { authorization.identity }
    let(:access_token) do
      t = AccessToken.new
      t.account = account
      t.client = client
      t
    end

    let(:oauth) do
      double 'oauth', \
        user_token?: false,
        app_token?: true,
        user_or_app_token?: true,
        server_token?: false,
        authenticated?: true,
        account_id: account.id,
        account: account.id,
        client_id: client.id,
        client: client
    end

    before do |example|
      if :controller == example.metadata[:type] && example.metadata[:example_group][:file_path] =~ %r{idnet/api}
        authorization
        allow(@controller).to receive(:oauth).and_return oauth
      end
    end
  end
end
