require 'spec_helper'

describe Idnet::Core::TokenEndpoint do
  let(:client) { create :client }
  let(:account) { create :confirmed_account }
  let(:basic_parameters) do
    {
      client_id:     client.id,
      client_secret: client.secret,
    }
  end
  let(:additional_parameters) { {} }
  let(:environment) do
    {
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new(basic_parameters.merge(additional_parameters).to_query)
    }
  end
  let(:status) { subject[0] }
  let(:headers) { subject[1] }
  let(:response) { subject[2] }
  let(:parsed_response) { JSON.parse response.body[0] }
  subject { described_class.new.call environment }

  describe 'getting token in exchange for authorization_code' do
    let(:authorization_code_attributes) { {} }
    let(:authorization_code) do
      create :authorization_code, {
        client:  client,
        account: account
      }.merge(authorization_code_attributes)
    end
    let(:additional_parameters) do
      {
        redirect_uri:  client.redirect_uri,
        grant_type:    :authorization_code,
        code:          authorization_code.token,
      }
    end

    it 'returns HTTP 200' do
      expect(status).to eq 200
    end

    it 'creates and returns access_token' do
      expect do
        expect(parsed_response['access_token']).to be_present
      end.to change AccessToken, :count
    end

    it 'creates and returns refresh_token' do
      expect do
        expect(parsed_response['refresh_token']).to be_present
      end.to change RefreshToken, :count
    end

    it 'sets attributes of refresh_token' do
      subject
      refresh_token = RefreshToken.last
      expect(refresh_token.account).to eq account
      expect(refresh_token.client).to eq client
    end

    context 'when authorization_code has expired' do
      let(:authorization_code_attributes) { {expires_at: 1.day.ago} }

      it 'returns HTTP 400' do
        expect(status).to eq 400
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_grant'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end

    context 'when no client_id parameter is supplied' do
      before { basic_parameters.delete :client_id }

      it 'returns HTTP 400' do
        expect(status).to eq 400
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_request'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end

    context 'when no client_secret parameter is supplied' do
      before { basic_parameters.delete :client_secret }

      it 'returns HTTP 401' do
        expect(status).to eq 401
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_client'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end

    context 'when no code parameter supplied' do
      before { additional_parameters.delete :code }

      it 'returns HTTP 400' do
        expect(status).to eq 400
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_request'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end
  end

  describe 'getting client token' do
    let(:additional_parameters) { {grant_type: :client_credentials} }

    it 'returns HTTP 200' do
      expect(status).to eq 200
    end

    it 'creates and returns access_token' do
      expect do
        expect(parsed_response['access_token']).to be_present
      end.to change AccessToken, :count
    end

    it 'does not create refresh_token' do
      expect do
        expect(parsed_response['refresh_token']).not_to be_present
      end.not_to change RefreshToken, :count
    end
  end

  context 'when unsupported grant_type is supplied' do
    let(:additional_parameters) { {grant_type: :parole} }

    it 'returns HTTP 400' do
      expect(status).to eq 400
    end

    it 'returns error' do
      expect(parsed_response['error']).to eq 'unsupported_grant_type'
    end

    it 'does not create and return access_token' do
      expect do
        expect(parsed_response['access_token']).to be_nil
      end.not_to change AccessToken, :count
    end
  end

  context 'when no grant_type parameter is supplied' do
    it 'returns HTTP 400' do
      expect(status).to eq 400
    end

    it 'returns error' do
      expect(parsed_response['error']).to eq 'invalid_request'
    end

    it 'does not create and return access_token' do
      expect do
        expect(parsed_response['access_token']).to be_nil
      end.not_to change AccessToken, :count
    end
  end

  context 'when grant_type == password is supplied' do
    let(:additional_parameters) { {grant_type: :password, username: 'Jon Doe', password: 'password'} }

    it 'returns HTTP 400' do
      expect(status).to eq 400
    end

    it 'returns error' do
      expect(parsed_response['error']).to eq 'unsupported_grant_type'
    end

    it 'does not create and return access_token' do
      expect do
        expect(parsed_response['access_token']).to be_nil
      end.not_to change AccessToken, :count
    end
  end

  context 'when grant_type == refresh_token is supplied' do
    let(:refresh_token_attributes) { {} }
    let!(:refresh_token) { create :refresh_token, {client: client, account: account}.merge(refresh_token_attributes) }
    let(:additional_parameters) { {grant_type: :refresh_token, refresh_token: refresh_token.token} }

    it 'returns HTTP 200' do
      expect(status).to eq 200
    end

    it 'creates access_token' do
      expect do
        subject
      end.to change AccessToken, :count
    end

    it 'renders access_token' do
      subject
      expect(parsed_response['access_token']).to eq AccessToken.last.token
    end

    it 'sets attributes of access_token' do
      subject
      access_token = AccessToken.last
      expect(access_token.account).to eq account
      expect(access_token.client).to eq client
    end

    it 'does not create another refresh_token' do
      expect do
        subject
      end.not_to change RefreshToken, :count
    end

    it 'does not render refresh_token' do
      subject
      expect(parsed_response['refresh_token']).not_to be_present
    end

    context 'when refresh_token belongs to another client' do
      let(:refresh_token_attributes) { {client: create(:client)} }

      it 'returns HTTP 400' do
        expect(status).to eq 400
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_grant'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end

    context 'when refresh_token has expired' do
      let(:refresh_token_attributes) { {expires_at: 1.day.ago} }

      it 'returns HTTP 400' do
        expect(status).to eq 400
      end

      it 'returns error' do
        expect(parsed_response['error']).to eq 'invalid_grant'
      end

      it 'does not create and return access_token' do
        expect do
          expect(parsed_response['access_token']).to be_nil
        end.not_to change AccessToken, :count
      end
    end
  end
end
