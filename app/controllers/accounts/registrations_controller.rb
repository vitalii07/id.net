class Accounts::RegistrationsController < Devise::RegistrationsController
  layout :current_layout

  prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
  skip_before_filter :verify_authenticity_token, only: [:quick_register]
  prepend_before_filter :authenticate_scope!, :only => [ :change_email, :edit ]
  prepend_before_filter :check_if_account_confirmed, only: :change_email

  def new
    @account = build_resource({})
    action = 'new'

    if client_id_param || params[:quick].present?
      @client = Client.where(_id: client_id_param).first
      if @client.nil?
        Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.quick.fail")
        flash[:error] = t('accounts.registrations.new.error.client_not_exist')
        redirect_to root_path and return
      end
    end

    if params[:quick]
      action   = 'accounts/new'

      @identity = @account.identities.build
      @identity.address = Address.new
      @identity.prefill params[:prefill]

      # TODO ConfimationsController#after_confirmation_path_for comments

      flash[:notice] = "After registration on ID.NET you will be automatically redirected to
                        #{client_alternate_name(@client)} application authorization procedure" if @client.present?
      Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.quick.show")
    else
      Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.form.show")
    end

    # TODO decide when we display instant registration form and when go standard AUTH way
    respond_with(@account) { render action and return }
  end

  def create
    build_resource(sign_up_params)
    resource.terms_of_service = '1'
    @client = Client.where(_id: params[:client_id]).first

    Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.form.submit")

    if resource.save
      # set consumer id to pass via confirmation email instructions
      registration_parameters = {
        tracking: cookie_tracking_hash,
        consumer: client_id_param,
        prefill: params[:prefill],
        authorization: params[:authorization],
        redirect_uri: params[:redirect_uri],
        scope: params[:scope],
        state: params[:state],
        ioBB: params[:ioBB],
        ip: request.remote_ip,
      }
      if params[:hostname]
        registration_parameters[:tracking][:hostname] = params[:hostname]
      end
      resource.set(registration_parameters: HashWithIndifferentAccess.new(registration_parameters))
      resource.check_device_fingerprint(ip: request.remote_ip, type: 'registration', client: @client)

      set_flash_message :notice, :signed_up if is_navigational_format?

      sign_in(resource_name, resource)
      ga_params = {event_type: "authentication", event_action: "register"}
      url = existing_oauth_path(registration_parameters.merge(ga_params)) || authenticated_root_path(ga_params)
      Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.form.success")
      respond_with resource, :location => url
    else
      Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.form.fail")
      clean_up_passwords resource
      respond_with resource
    end
  end

  def quick_register
    email = params[:email]
    password = params[:password]
    @client = Client.where(_id: client_id_param).first

    if @client
      otp = HSign::Digest.new(@client.secret, request.remote_ip)
      if otp.verify?(request.POST)
        @account = Account.where(email: email).first
        @account ||= Account.new do |account|
          account.email = email
          account.password = password
          account.password_confirmation = password
          account.terms_of_service = '1'
        end

        @account.skip_confirmation!
        @account.save
        sign_in :account, @account
        Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.quick.success")

        url = authorize_path(params.slice(:client_id, :redirect_uri, :response_type, :scope, :state).merge(event_type:"authentication", event_action:"register", event_value: client_id_param))
        redirect_to url and return
      end
    end
    Stats.increment("account.reg.#{detect_browser}.#{current_game_slug}.quick.fail")
    # TODO : clean
    # Ugly because of denormalized parameters
    redirect_to new_account_registration_path(params.slice(:redirect_uri, :response_type, :scope, :state).merge(consumer: client_id_param))
  end

  def change_email
    authorize! :change_email, current_account

    if current_account.update_attributes(params[:account].slice(:email, :email_confirmation))
      Account.send_confirmation_instructions(email: current_account.email)
      path = params[:registration].present? ? edit_account_registration_path : root_certification_path
      redirect_to path, notice: I18n.t('accounts.email.changed_confirm',
                                       default: 'Email was successfully changed, please check your email to confirm.')
    else
      template = if params[:registration].present?
        'accounts/registrations/edit'
      else
        'certifications/email'
      end
      render template
    end
  end

  def language
    current_account.language = params[:account][:language]
    current_account.save
    redirect_to settings_path, notice: I18n.t('devise.registrations.updated')
  end

  private

  def check_if_account_confirmed
    if current_account.confirmed?
      path = params[:registration].present? ? edit_account_registration_path : root_certification_path
      redirect_to path, alert: I18n.t('accounts.email.cannot_change_account_confirmed',
                                      default: 'Your account was confirmed, you can not change this Email')
    end
  end

  def current_layout
    if params[:popup_window]
      "popup"
    elsif action_name == "update" || action_name == "edit" || action_name == "change_email"
      return "certification" if params[:certification].present?
      "application"
    else
      "sign_in"
    end
  end

  def require_no_authentication
    assert_is_devise_resource!
    return unless is_navigational_format?
    no_input = devise_mapping.no_input_strategies

    authenticated = if no_input.present?
      args = no_input.dup.push :scope => resource_name
      warden.authenticate?(*args)
    else
      warden.authenticated?(resource_name)
    end

    client = Client.find(client_id_param) rescue nil

    if authenticated
      if client
        if params[:authorization]
          path = authorize_path(params.reverse_merge(authorization: params[:authorization]))
        else
          path = authorize_path(params.reverse_merge(response_type: "code", client_id: client.id, redirect_uri: client.redirect_uri))
        end
        redirect_to path
      else
        resource = warden.user(resource_name)
        flash[:alert] = I18n.t("devise.failure.already_authenticated")
        redirect_to after_sign_in_path_for(resource)
      end
    end
  end

  protected

  def current_game_slug
    @client.try(:slug) || 'unknown'
  end

  def existing_oauth_path(hash)
    if hash[:consumer] || hash[:authorization]
      authorize_path(hash.slice(:consumer, :redirect_uri, :prefill, :scope, :state, :authorization, :response_type).reverse_merge(response_type: 'code'))
    end
  end

  # Set alternate name for client.display_name
  def default_url_options_without_override
    super.merge(alternate_name.present? ? {prefill: {alternate: alternate_name}} : {})
  end
end
