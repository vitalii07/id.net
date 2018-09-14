class AccountsController < ApplicationController
  layout 'sign_in'

  helper_method :authorize_params

  def create
    @client = Client.find(client_id_param) rescue nil
    redirect_to(:root) and return if @client.nil?

    normalize_birth_date
    @account, @identity, device = Account.register(account_params, against: @client).values_at(:account, :identity, :device)

    if @account.persisted?
      session[:current_device] = device

      sign_in :account, @account

      url = authorize_path(authorize_params.merge({event_type: "authentication", event_action: "register", event_value: client_id_param}))
      redirect_to url
    else
      @errors = (@account.errors.flat_messages + @identity.errors.flat_messages).uniq
      render :new
    end
  end

  private

  def account_params
    h = params.merge(ip: request.remote_ip)
    h[:meta_real] = (h[:meta] || {}).slice(:nickname)
    h[:tracking] = cookie_tracking_hash
    h
  end

  def authorize_params
    params.slice(:redirect_uri, :response_type, :scope, :state, :prefill).reverse_merge(client_id: client_id_param, redirect_uri: @client.redirect_uri, response_type: 'code')
  end
end
