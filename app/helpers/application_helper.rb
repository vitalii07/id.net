module ApplicationHelper
  include IovationHelper
  include Idnet::Core::MailerHelper
  include WebsiteHelper
  include Idnet::Api::ProfileHelper # for identity_profile_picture_url

  def flash_session_tag
    tag :meta, {content: flash_session_management, name: '_flC'}, true
  end

  def client_name_for_ga_event
    current_account.try(:registration_params).try(:[], 'client_name') || Client.where(_id: params[:event_value]).first.try(:display_name)
  end

  def admin_time_format(time)
    if time.class == String
      time = Time.parse(time)
    end
    I18n.l(time, format: :long) if time.present?
  end

  def admin_kibana_url
    Idnet.config.application.kibana_admin_url
  end

  def flash_div content, name
    content_tag :div, content, :id => "flash_#{name}" if content.is_a?(String)
  end

  def page_tracking_enabled?
    Rails.env.production?
  end

  def idnet_root_path(opts = {})
    if account_signed_in? && controller_name !~ %r{^admin}
      if current_identity?(mock_identity)
        authenticated_root_path(opts.merge(scope_id: nil))
      else
        authenticated_root_path(opts)
      end
    else
      root_path(opts)
    end
  end

  def resource_name
    :account
  end

  # Shows current git brange only for staging environment. See config/deploy.rb deploy:put_git_branch task
  def show_git_branch_for_staging
    "<p class='header-top-notice'>Current branch: <strong> #{render :partial => 'git'}</strong></p>".html_safe if Rails.env == 'staging'
  end

  def client_authorize_url(client)
    authorize_path(:response_type => :code, :client_id => client.id,
                   :redirect_uri => client.redirect_uri)
  end

  def tos_and_privacy_policy_html(client)
    txt = ''
    if client_alternate_tos(client)
      txt = t('authorization.text.accept_alternate_tos_html',
      site_name: client_alternate_name(client),
      tos_link: link_to(t('authorization.text.terms_of_service'), client_alternate_tos(client), target: "_blank"),
      privacy_link: link_to(t('authorization.text.privacy_policy'), client_alternate_privacy_policy(client), target: "_blank")).html_safe
      txt = txt + ' &amp; '.html_safe
    end
    txt = txt + t('authorization.text.accept_idnet_tos_html',
    register_button_text: t('registration.forms.buttons.register'),
    tos_link: link_to(t('authorization.text.terms_of_service'), terms_of_service_path({}), target: "_blank"),
    privacy_link: link_to(t('authorization.text.privacy_policy'), privacy_policy_path({}), target: "_blank"))
    txt.html_safe
  end

  def image_for_client(client)
    client.try(:image_url).presence || "default_app_bg.png"
  end

  def display_field?(field)
    if current_site
      current_site.form_field? field
    else
      true
    end
  end

  def language_name(abbr)
    LANG_LIST[abbr] || ''
  end

  def country_name country=nil
    ::Carmen::Country.coded(country).try(:name) || country if country.present?
  end

  def display_errors(record)
    return unless record && record.errors.any?
    content_tag :div, id: 'error_explanation' do
      content_tag :ul do
        record.errors.full_messages.map do |msg|
          content_tag :li, msg
        end.join.html_safe
      end
    end
  end

  def identity_label(identity)
    content_tag(:span, class: ['label', class_for_identity(identity)]) do
      identity_title_i18n(identity.identity_title)
    end
  end

  # Convenient helper to returns current_account identities
  # By default it will returns the current_account identities
  # It may be overriden in other helpers
  # @return [Hash]
  def user_identities
    @user_identities ||= Hash.new{ current_account.identities }
  end

  def link_to_friends_list identity
    if current_account.identities.any? && current_account.identities_to_follow_with(identity).blank?
      link_to friends_path, class: 'has-tip button secondary tiny icon radius', title: t('friends.already_following_this_user') do
        "<i class='icon-ok'></i>".html_safe
      end
    end
  end

  def link_to_write_message identity
    url = new_conversations_path(scope_id: user_identities[identity.id][:write_message].first || current_account.identities.first, recipient_id: identity.id)

    link_to url, class: 'has-tip action js-button search-results-actions button tiny icon secondary radius',
      title: t('friends.actions.write_message'), method: :get, # TODO method get?
      data: {action: 'write_message', 'reveal-id' => "select-#{identity.id}-write_message"} do
      "<i class='icon-envelope'></i>".html_safe
    end
  end

  def link_to_follow identity
    if user_identities[identity.id][:follow].present?
      url = follow_friend_path(identity, scope_id: user_identities[identity.id][:follow].first || current_account.identities.first)

      link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
        title: t('friends.actions.connect_with', identity_title: identity_title(identity)),
        data: {action: 'follow', 'reveal-id' => "select-#{identity.id}-follow", 'id-track-event' => 'friend-request-sent'} do
        #tag "i", class: "icon-plus" # rails makes <i> self-closing which is incorrect
        "<i class='icon-add-contact'></i>".html_safe
      end
    end
  end

  def sanitize_string message, p_class = nil
    simple_format(strip_tags(message), :class => p_class)
  end

  def link_to_unfollow identity
    url = unfollow_friend_path(identity, scope_id: user_identities[identity.id][:unfollow].first)

    link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
      title: t('friends.actions.unfollow'),
      data: {action: 'unfollow', 'reveal-id' => "select-#{identity.id}-unfollow"} do
      "<i class='icon-minus'></i>".html_safe
    end
  end

  def link_to_block identity
    url = block_friend_path(identity, scope_id: user_identities[identity.id][:block].first)

    link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
      title: t('friends.actions.block'),
      data: {action: 'block', 'reveal-id' => "select-#{identity.id}-block"} do
      "<i class='icon-ban-circle'></i>".html_safe
    end
  end

  def link_to_mutual_accept identity
    url = add_as_friend_path(identity, scope_id: user_identities[identity.id][:mutual_accept].first)


    link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
      title: t('friends.actions.add_as_friend'),
      data: {action: 'mutual_accept', 'reveal-id' => "select-#{identity.id}-mutual_accept", 'id-track-event' => 'friend-request-accept'} do
      "<i class='icon-add-contact'></i>".html_safe
    end
  end

  def link_to_unblock identity
    url = unblock_friend_path(identity, scope_id: user_identities[identity.id][:unblock].first)

    link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
      title: t('friends.actions.unblock'),
      data: {action: 'unblock', 'reveal-id' => "select-#{identity.id}-unblock"} do
      "<i class='icon-ok'></i>".html_safe
    end
  end

  def link_to_accept identity
    url = accept_friend_path(identity, scope_id: user_identities[identity.id][:accept].first)

    link_to url, class: 'has-tip action js-button button tiny icon secondary radius', method: :post,
      title: t('friends.actions.keep_as_follower'),
      data: {action: 'accept', 'reveal-id' => "select-#{identity.id}-accept"} do
      "<i class='icon-ok'></i>".html_safe
    end
  end

  # Renders a link to account by account id and link text. Does not require account model.
  def link_to_referenced_account(account_id, link_value)
    output = if can? :read, Account
      link_to link_value, admin_account_path(account_id)
    else
      link_value
    end

    output += ' '
    output += link_to_external_iovation_resource 'accountLookup', account_id

    output.html_safe
  end

  # Renders a link to Account in Admin section and a link to open Iovation
  # Account details window
  #
  # @param account [Account]
  # @return [ActiveSupport::SafeBuffer]
  def link_to_account(account, display_field = :_id)
    output = if can? :read, Account
      link_to account[display_field].to_s, admin_account_path(account),
        class: "account-status-#{account.status}"
    else
      account[display_field]
    end
    output += ' '
    output += link_to_external_iovation_account(account)

    output.html_safe
  end

  # Renders a link to IovationTransaction in Admin section and a link to open
  # Iovation Transaction details window
  #
  # @param iovation_transaction [IovationTransaction]
  # @return [ActiveSupport::SafeBuffer]
  def link_to_iovation_transaction(iovation_transaction)
    output = if can? :read, IovationTransaction
      link_to iovation_transaction.id,
        admin_transaction_path(iovation_transaction)
    else
      iovation_transaction.id
    end
    output += ' '
    output += link_to_external_iovation_transaction iovation_transaction

    output.html_safe
  end

  def auth_request
  end

  def popup_login_title
    id = auth_request.try(:client).try(:id) || session[:client_id]
    client = Client.where(_id: id).first if id

    if client
      t('registration.text.login_with_client', client_name: client_alternate_name(client))
    else
      "Login"
    end
  end

  def current_resource_path(identity)
    if controller_name == "identities"
      if identity == mock_identity
        identities_path(scope_id: nil)
      elsif action_name.in? %w(index new create show)
        identity_path(identity, scope_id: nil)
      else
        edit_identity_path(identity, scope_id: nil)
      end
    else
      url_for request.path_parameters.merge(scope_id: identity)
    end
  end

  def class_for_identity(identity)
    @classes_for_identity ||= {}.tap do |cls|
      cls[mock_identity] = 'all-identities'
      current_account.identities.each_with_index do |identity, i|
        cls[identity] = "id_#{i % 9 + 1}"
      end
    end.freeze

    @classes_for_identity[identity]
  end

  def identity_title_i18n(identity_title)
    case identity_title
    when 'All Identities'
      I18n.t('identities.title.all_identities', default: 'All Identities')
    when 'Anonymous'
      I18n.t('identities.title.anonymous', default: 'Anonymous')
    when 'Real Identity'
      I18n.t('identities.title.real_identity', default: 'Real Identity')
    else
      identity_title
    end
  end

  # display Identities list and More menu for them
  def identities_menu_list(identities, options = {max_length: 30}, &block)
    raise "current_account required" unless current_account

    identities.each do |identity|
      title = truncate(identity_title_i18n(identity.identity_title), length: options[:max_length])
      link = link_to title, current_resource_path(identity)
      current_class = current_identity?(identity) ? "active" : ""
      yield(link, class: current_class)
    end
    nil
  end

  def iovation_javascript_file
    Idnet.config.iovation.snare_js_url
    # "http://localhost:3000/iovation.js"
  end

  def admin_path_for_role
    case current_account.try(:role).to_s
    when 'comment_moderator'
      admin_comments_path
    end
  end

  # some roles have no access to admin/accounts#index. quick solution
  def admin_dashboard_path
    given = admin_path_for_role
    return given if given
    if can? :read, Account
      admin_main_dashboard_path
    elsif can? :read, Certification
      admin_certifications_path
    elsif can? :review, :comment
      admin_comments_path
    else
      admin_main_dashboard_path # fall back to dashboard and hope for best
    end
  end

  def detect_country(model)
    country = ""
    if model.country.present?
      country = model.country
    elsif $geoip.try(:country, request.try(:remote_ip))
       country = $geoip.country(request.remote_ip).country_code3
    end
    return country
  end

  # Returns current page identifier. Useful for JS.
  def data_page
    controller_name.camelize + action_name.capitalize
  end

  # display profile picture (avatar)
  def identity_profile_picture(identity, options={}, html_options={})
    pic = identity.profile_picture
    options[:style] ||= :large

    tags = []

    url = identity_profile_picture_url(identity, style: options[:style], secure: request.ssl?)

    if pic.present?
      if pic.pending?
        tags << content_tag(:span, "Your picture is pending moderation", class: "watermark status-pending")
      elsif pic.rejected?
        tags << content_tag(:span, "Your picture has been rejected by moderators", class: "watermark status-rejected")
      end
    end

    html_options[:class] = (html_options[:class] || '').split.push("profile-picture #{options[:style]}").join ' '
    html_options[:alt] = nil

    if identity.real?
      tags.prepend image_tag('avatar-real-id.png', html_options)
      content_tag :div, tags.join.html_safe, class: "profile-picture-container #{options[:style]}"
    else
      tags.prepend image_tag(url, html_options)
      content_tag :div, tags.join.html_safe, class: "profile-picture-container #{options[:style]}"
    end
  end

  def dialogs_identity_profile_picture(identity, options={}, html_options={})
    tags = []
    url = identity_profile_picture_url(identity, style: options[:style])
    tags.prepend image_tag(url, html_options)
    content_tag :div, tags.join.html_safe, class: "profile-picture-container #{options[:style]}"
  end

  def available_locales_items
    result = ''
    opts = {}
    opts = {method: :post} if request.post?

    I18n.available_locales.each do |locale|
      result += content_tag(:li, link_to(locale_item_for(locale) + ' ' + LANG_LIST[locale.to_s], params.except(:authenticity_token, :controller, :action, :_method).merge({locale: locale}), opts))
    end

    result.html_safe
  end

  def locale_item_for locale
    image_tag('icons/flags/' + LOCALE_FLAG_MAP[locale.to_s])
  end

  def current_locale
    I18n.locale
  end

  def li_to(url, active=nil, &block)
    html_opts = {}

    if active.nil?
      html_opts[:class] = "active" if current_page?(url)
    else
      html_opts[:class] = "active" if active
    end

    content = capture(&block)
    content_tag :li, html_opts do
      link_to content, url
    end
  end

  # TODO Support model/controller/routes are replaced by zendesk. Remove them?
  def zendesk_form_link
    link_to t('application.footer.text.contact'), zendesk_form_path, onClick: "script: Zenbox.show(); return false;"
  end

  def zendesk_form_path
    "https://idsupport.zendesk.com/account/dropboxes/#{Idnet.config.zendesk.dropbox_id}"
  end

  def app_image client
    unless client.image_url.blank?
      image_tag client.image_url
    else
      image_tag "default_app.png"
    end
  end

  def display_email_confirmation_notice?
    if current_account
      !current_account.confirmed? && !session[:hide_email_confirmation_reminder]
    end
  end

  # use this with care, it will break login as user feature
  def link_to_app_link(client)
    without_default_url_options do
      url = client.app? ? canva_url(subdomain: 'apps', id: client.slug) : client.link
      link_to url.to_s, url, target: :blank
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    icon = ""
    icon = "<i class=\"icon-sort-alt-#{direction=='asc' ? 'down' : 'up'}\"></i>" if column == sort_column
    link_to (icon+title).html_safe, params.merge({:sort => column, :direction => direction})
  end

  def client_label_type status
    case status
    when 'accepted'
      'success'
    when 'rejected'
      'alert'
    when 'pending'
      'pending'
    end
  end

  def static_url(path, options = {})
    asset_host = IdNet::Application.config.action_controller.asset_host
    if asset_host
      if options[:secure] && Idnet.config.application.enable_ssl
        uri = URI.parse asset_host.secure_url
      else
        uri = URI.parse asset_host.cdn_url
      end
      uri.path = File.join('/', path)
      uri.to_s
    else
      File.join('/', path)
    end
  end

  def adsrevshare_url
    Idnet.config.application.adsrevshare_url
  end

  def tracking_url(client = nil)
    "#{Idnet.config.application.tracking_url}/reports/game_stats?game_id=#{client.id}"
  end

end
