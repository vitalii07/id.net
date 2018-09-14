# encoding: utf-8

require 'spec_helper'

describe ClientEventSubscriber do
  let(:account) { create :account, registration_parameters: { 'redirect_uri' => 'http://redirect/uri' } }
  let(:client) { create :client, push_event_url: 'http://ticket/path' }
  let(:authorization) { create :authorization, account: account, client: client }
  let(:hsign) { HSign::Digest.new(client.secret, client.id) }

  shared_examples_for 'push_event_to_client' do |event|
    let(:args) { [ event, Time.now, Time.now, account.id, account_id: account.id ] }
    let(:params_block) do
      if event.split('.').last == 'agent'
        redirect_uri = account.registration_parameters['redirect_uri']
        expect_any_instance_of(Authorization).to receive(:account).and_return(account)
        code = AuthorizationCode.new(token: SecureRandom.hex)
        mock_code = double('code', create: code)
        expect(account).to receive(:authorization_codes).and_return(mock_code)
        hsign.sign(pid: authorization.id, event_name: event, grant_code: code.token, redirect_uri: account.registration_parameters['redirect_uri'])
      else
        hsign.sign(pid: authorization.id, event_name: event)
      end
    end

    it 'should call asynk_call' do
      expect(ClientEventSubscriber).to receive(:asynс_call).with(args)
      subject.call args
    end

    it 'should call synk_call' do
      expect(ClientEventSubscriber).to receive(:synс_call).with(args)
      ClientEventSubscriber.asynс_call args
    end

    it 'should call with client_id' do
      args.last.merge!(client_id: client.id)
      params_block
      stub_request(:post, client.push_event_url).with(:body => hsign.params.to_json).to_return(:status => 200)
      ClientEventSubscriber.synс_call *args
    end

    it 'should call for all authorizations clients' do
      params_block
      stub_request(:post, client.push_event_url).with(:body => hsign.params.to_json).to_return(:status => 200)
      ClientEventSubscriber.synс_call *args
    end
  end

  ClientEventObserver::USER_EVENTS.each do |event|
    it_behaves_like 'push_event_to_client', event
  end

  ClientEventObserver::AGENT_EVENTS.each do |event|
    it_behaves_like 'push_event_to_client', event
  end
end
