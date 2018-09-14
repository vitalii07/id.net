require 'spec_helper'

describe AccountsController do
  before do
    allow(Idnet.config.application).to receive(:enable_iovation).and_return true
    allow(Idnet.config).to receive(:reload!)
  end

  let(:client) { create :client }

  let(:parameters) do
    { email: 'user@id.net',
      password: 'password',
      password_confirmation: 'password',
      terms_of_service: '1',
      meta: { nickname: 'Ivan', city: 'Kiev', country: 'UKR' },
      consumer: client.id }
    end

  before do
    client.identity_form.attributes = {email: true, address: %w{city country}}
    client.save!
    request.env["devise.mapping"] = Devise.mappings[:account]
    Devise.mailer.deliveries.clear
  end

  it 'should create authorized client' do
    expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:review))
    post :create, parameters
    response.should redirect_to authorize_path(redirect_uri: client.redirect_uri, response_type: 'code', client_id: client.id, event_type: "authentication", event_action: "register", event_value: client.id)
    assigns(:client).should == client
    assigns(:account).should be_valid
    assigns(:identity).should be_valid
  end

  it 'should create authorized client if password is nil' do
    expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:review))
    parameters.delete(:password)
    parameters.delete(:password_confirmation)
    post :create, parameters

    response.should be_redirect

    assigns(:account).should be_persisted
    assigns(:identity).should be_persisted
    assigns(:account).should be_reset_password_token
  end

  context 'Check device fingerprint' do
    let(:params) { parameters.merge(ioBB: SoapFixture.body(:request)[:check_transaction_details][:beginblackbox]) }

    it 'should create authorized client and confirm status' do
      expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:allow))
      post :create, params
      controller.should be_account_signed_in
      response.should redirect_to authorize_path(redirect_uri: client.redirect_uri, response_type: 'code', client_id: client.id, event_type: "authentication", event_action: "register", event_value: client.id)
      assigns(:account).should be_allow
    end

    it 'should create authorized client and review status' do
      expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:review))
      post :create, params
      response.should be_redirect
      assigns(:account).should be_review
    end

    it 'should create authorized client and deny status' do
      expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:deny))
      post :create, params
      response.should be_redirect
      assigns(:account).should be_deny
    end
  end

  it 'should render new if params are not valid' do
    post :create, identity: { address: {} }, account: {}, consumer: client.id
    response.should render_template(:new)
    assigns(:client).should == client
    errors = (assigns(:account).errors.flat_messages +
              assigns(:identity).errors.flat_messages).uniq
    assigns(:errors).should == errors
  end

  it 'should have correct redirect_uri' do
    parameters[:redirect_uri] = "http://check.com/callback"
    parameters[:password] = ""
    post :create, parameters
    controller.send(:authorize_params)[:redirect_uri].should == "http://check.com/callback"
  end

  it 'should redirect to root if client not found' do
    parameters.delete(:consumer)
    post :create, parameters
    response.should redirect_to(:root)
    assigns(:client).should be_nil
  end

  context 'Normalize date_of_birth' do
    before do
      client.identity_form.set(date_of_birth: true)
    end

    it 'should be nil' do
      parameters[:meta].merge!('date_of_birth(2i)'=>'12', 'date_of_birth(3i)'=>'2010')
      post :create, parameters
      response.should be_success
      assigns(:identity).date_of_birth.should be_nil
      assigns(:identity).errors[:date_of_birth].should_not be_empty
    end

    it 'should be not valid' do
      parameters[:meta].merge!('date_of_birth(3i)' => '10', 'date_of_birth(2i)'=>'12', 'date_of_birth(1i)'=>'1899')
      post :create, parameters
      response.should be_success
      assigns(:identity).date_of_birth.should_not be_nil
      assigns(:identity).errors[:date_of_birth].should_not be_empty
    end

    it 'should be valid' do
      expect(HTTPI).to receive(:post).and_return(SoapFixture.response(:review))
      parameters[:meta].merge!('date_of_birth(3i)' => '10', 'date_of_birth(2i)'=>'12', 'date_of_birth(1i)'=>'2010')
      post :create, parameters
      response.should be_redirect
      assigns(:identity).date_of_birth.should_not be_nil
      assigns(:identity).errors[:date_of_birth].should be_empty
    end
  end
end
