class Idnet::Api::V1::AccountsController < Idnet::Api::ApplicationController
  helper Idnet::Api::ProfileHelper

  rescue_from Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound do |exception|
    render status: 404, json: {error: 'Document not found'}
  end

  attr_reader :client, :account

  protected :client, :account
  helper_method :client, :auth, :account

  def role
    authorization = Authorization.find(params[:user_id])
    return render status: 404 unless authorization
    render json: { role: authorization.account.role }
  end

  def applications
    authorization = Authorization.find(params[:user_id])
    return render status: 404 unless authorization
    render json: { applications: authorization.account.applications.map { |a| a['_id'] } }
  end

  def create
    email = params[:email]
    password = params[:password]
    timestamp = params[:timestamp]
    @client = Client.find(params[:client_id]) rescue nil
    if @client && @client.api_registration_access?
      Stats.increment("account.reg.api.#{current_game_slug}.api.submit")
      otp = HSign::Digest.new(@client.secret)
      if otp.verify?(params.slice(:email, :password, :_hmac, :timestamp))
        @account, @identity = Account.register(register_parameters, account_options).values_at(:account, @client.checkout? ? :real_identity : :identity)

        #since we disabled security plicy functionality, commenting out this check for now
        #security_policy = SecurityPolicy.new(@account, @client)
        if @account.persisted? #  && security_policy.authorized_by_client?
          @token = @account.access_tokens.create(client: client).to_bearer_token(:with_refresh_token)
          Stats.increment("account.reg.api.#{current_game_slug}.api.success")
        else
          Stats.increment("account.reg.api.#{current_game_slug}.api.fail")
          render status: 403
        end
        return
      end
    end

    unless @client
      render json:
        {
          error: 'Unauthorized',
          details: "Could not find client site. Please, check application ID."
        }, status: 401
        return
    else
      otp = HSign::Digest.new(@client.secret)
      render json:
        {
          error: 'Invalid parameters',
          details:
            {
              client_site: @client.try(:display_name),
              timestamp_valid: timestamp_valid?,
              api_registration_access: @client.try(:api_registration_access?),
              hsign_digest_verify: otp.verify?(params.slice(:email, :password, :_hmac, :timestamp))
            }
        }, status: 401
    end
  end

  def update
    @client = Client.find(params[:client_id])
    @account = find_account_by_pid params[:id], @client
    if @account.confirmed?
      render json: {error: "Account already confirmed"}, status: 403
      return
    end

    otp = HSign::Digest.new(@client.secret)
    if otp.verify?(params.slice(:id, :email, :password, :_hmac, :timestamp))
      @account.email = params[:email]
      @account.email_confirmation = params[:email]

      if params[:password].present?
        @account.password = params[:password]
        @account.password_confirmation = params[:password]
      end
      @account.send_confirmation_instructions if @account.save
    else
      render json: {error: "Invalid signature"}, status: 403 if @account.confirmed?
    end
  end

  private

  def find_account_by_pid(pid, client)
    authorization = Authorization.where(_id: pid, client_id: client.id).first
    account = authorization.try(:account)
    raise Mongoid::Errors::DocumentNotFound.new(Account, pid: pid) unless account
    account
  end

  def auth
    @account.authorizations.authorized.where(client_id: client.id).first
  end

  def register_parameters
    register_params = params.slice(:email, :password, :meta, :ioBB, :redirect_uri, :skip_client_validation, :prefill, :ip)
    register_params[:password_confirmation] = register_params[:password]
    register_params[:meta_real] = register_params[:meta]
    register_params
  end

  def account_options
    {
      against: @client, skip_tos: true,
      skip_fingerprint: false,
      skip_client_validation: register_parameters.delete(:skip_client_validation)
    }
  end

  def current_game_slug
    @client.try(:slug) || 'unknown'
  end
end
