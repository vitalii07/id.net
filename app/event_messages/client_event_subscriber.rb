# encoding: utf-8

class ClientEventSubscriber
  def call(*args)
    # name, start, finish, id, payload = args
    # raise payload[:exception] == ['class name', 'message']
    ClientEventSubscriber.asynс_call(*args)
  end

  def self.asynс_call(*args)
    if Rails.env.production?
      Resque.enqueue(ClientEventNotifier, *args)
    else
      Thread.new { synс_call(*args) }
    end
  end

  def self.synс_call *args
    name, start, finish, id, payload = args
    payload = HashWithIndifferentAccess.new payload
    account = Account.where(_id: payload[:account_id]).first

    if payload[:client_id].present?
      auth = Authorization.where(account_id: account.id, client_id: payload[:client_id]).first
      post auth, pid: auth.id, event_name: name
    else
      account.authorizations.each do |auth|
        post auth, pid: auth.id, event_name: name
      end
    end
  end

  def self.extract_params_from auth, params
    case params[:event_name]
      when *ClientEventObserver::AGENT_EVENTS
        account, client = auth.account, auth.client
        redirect_uri = account.registration_parameters['redirect_uri']
        code = account.authorization_codes.create(client_id: client.id, redirect_uri: redirect_uri, scope: [], token_class: 'app')
        params.merge(grant_code: code.token, redirect_uri: redirect_uri)
      when *ClientEventObserver::USER_EVENTS
        params
    end.reject{|k,v| v.blank? }
  end

  def self.post auth, params
    client = auth.client
    return if client.try(:push_event_url).blank?

    uri = URI(client.push_event_url)
    http = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')

    digest = HSign::Digest.new(client.secret, client.id)
    digest.sign(extract_params_from(auth, params))
    http.body = digest.params.to_json
    Net::HTTP.new(uri.host, uri.port).start{|h| h.request(http)}
  end
end
