class Agents::AccountsController < Admin::BaseController
  load_and_authorize_resource :account, class: 'Account'
  skip_authorize_resource :account, only: [:new, :index, :create]

  before_filter :authorize_account, except: [:update, :destroy, :edit]
  before_filter :load_authorization_and_identity, only: [:edit, :update]
  before_filter :check_client, only: [:create, :update]
  before_filter :sanitize_parameters, only: [:create, :update]

  def index
    @accounts = current_account.registered_accounts.order_by([[:updated_at, :desc]]).page(params[:page]).per(50)
  end

  def new
    @identity = Identity.new
    @real_identity = Identity.new
  end

  def create
    user_params = params[:account]
    params[:identity][:nickname] ||= user_params[:email].to_s.split('@').first
    params[:identity][:nickname] = params[:identity][:nickname].rstrip
    # Take only nickname for anonymous identity
    user_params.merge!(agent_id: current_account.id, meta: params[:identity].slice(:nickname), meta_real: params[:identity])
    user_params.merge!(client_or_affiliate_options)

    @account, @real_identity, @identity = Account.register(user_params, client_params).values_at(:account, :real_identity, :identity)

    if @account.errors.empty? && @identity.errors.empty?
      flash[:notice] = "User #{@account.email} created"

      push_event_to_client USER_SIGNUP_AGENT, account_id: @account.id, client_id: params[:client_id]

      if params[:create]
        redirect_to new_agents_account_path
      else
        redirect_to agents_accounts_path
      end
    else
      @errors = (@identity.errors.full_messages + @account.errors.full_messages).uniq - ["Identities is invalid"]
      render :new
    end
  end

  def destroy
    @account.delete
    redirect_to agents_accounts_path, notice: "User #{@account.email} was deleted"
  end

  def update
    @identity.attributes = params[:identity].slice(:nickname)
    @real_identity.attributes = params[:identity]
    @account.attributes = params[:account]
    email_changed = @account.changed.include?('email')
    if params[:display_name] != @account.registration_parameters['client_name']
      @account.registration_parameters['client_name'] = params[:display_name]
    end

    if @authorization.client != @client
      @account.registration_parameters['consumer'] = @client.id
      @authorization.destroy!
      @client.create_authorization_for @identity

      @account.registration_parameters.merge!(client_or_affiliate_options.stringify_keys)
    end

    if @identity.save && @account.save && @real_identity.save
      Account.delay(queue: 'idnet_mailer').send_confirmation_instructions(email: @account.email) if email_changed
      redirect_to agents_accounts_path, notice: "User #{@account.email} was updated"
    else
      @errors = (@identity.errors.full_messages + @account.errors.full_messages).uniq
      render :edit
    end
  end

  private

  def default_url_options
    {}
  end

  def check_client
    @client = Client.where(:_id => params[:client_id]).first
    if @client.nil?
      flash[:error] = 'Client doesn\'t exist'
      redirect_to root_path and return
    end

    unless current_account.agent_sites.include?(@client) || current_account.admin?
      raise CanCan::AccessDenied.new("Not authorized!", :register, Account)
    end
  end

  def client_params
    { against: @client, skip_fingerprint: true, skip_tos: true, validate_anonymous: false, validate_real: false }
  end

  def authorize_account
    authorize! :register, Account
  end

  def load_authorization_and_identity
    @authorization = @account.authorizations.authorized.first
    # At first this was auth's connected identity, but we only fill in real identity here. Code smell.
    # ----
    # Update for this code smell. Needs check.
    @identity = @authorization.try(:identity)
    @real_identity = @account.lookup_real_identity
    @real_identity.save! unless @real_identity.persisted?
  end

  def sanitize_parameters
    params[:account].delete_if {|k,v| v.blank?}
    params[:identity] = (params[:identity] || {}).delete_if {|k,v| v.blank?}
    clean_multi_attribute params[:identity], "date_of_birth"
  end

  def client_or_affiliate_options
    if @client.affiliates.present?
      affiliate = @client.affiliates.where(display_name: params[:display_name]).first
      uri = URI.parse(affiliate.redirect_uri)
      link = "#{uri.scheme}://#{uri.host}"
      link += ":#{uri.port}" unless [80, 443].include? uri.port
      opts = { redirect_uri: affiliate.redirect_uri, client_name: affiliate.display_name, link: link }
      opts[:prefill] ||= {}
      opts[:prefill][:alternate] = affiliate.display_name
      opts[:prefill][:alternate_privacy_url] = affiliate.privacy_policy_uri
      opts[:prefill][:alternate_tos_url] = affiliate.terms_of_service_uri
      opts[:prefill].delete_if {|key, val| val.blank? }.stringify_keys!
      opts
    else
      { redirect_uri: @client.redirect_uri, link: @client.link }
    end
  end

  def clean_multi_attribute params, key
    if (params["#{key}(1i)"].present? || params["#{key}(2i)"].present? || params["#{key}(3i)"].present?)
      if (params["#{key}(1i)"].blank? || params["#{key}(2i)"].blank? || params["#{key}(3i)"].blank?)
        (1..3).each {|i| params["#{key}(#{i}i)"] = '' }
      end
    end
  end
end
