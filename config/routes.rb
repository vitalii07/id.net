require 'sidekiq/web'
IdNet::Application.routes.draw do

  constraints subdomain: 'apps' do
    root to: 'apps#index', as: 'apps_root'
  end

  constraints subdomain: 'demos' do
    get '/' => 'demos#index'
    get '*path', to: 'demos#serve', as: 'game_demo'
  end

  # CORE
  devise_for :accounts,
    controllers: {
      registrations: "accounts/registrations",
      confirmations: "accounts/confirmations",
      sessions: "accounts/sessions",
      passwords: "accounts/passwords" }

  post 'register' => "accounts#create", :as => :register

  devise_scope :account do
    get  'register' => "accounts/registrations#new", :as => :new_account_registration_2
    post 'registration' => "accounts/registrations#quick_register", :as => :quick_registration
    put 'email' => 'accounts/registrations#change_email', :as => :change_email
    match 'language' => 'accounts/registrations#language', :as => :language, via: [:get, :put]
  end

  # APP
  get "settings/index"
  resources :settings, :only => [:index]

  if Rails.env.development?
    get 'apps/index'
    get '/api/tracking' => 'cdn_utils#tracking'
    mount MailPreview => 'mail_view'
  end

  scope 'htaccess' do
    # Check for access to kibana
    match 'admin/kibana(/*other)', to: 'htaccess#kibana', via: [:get, :post, :delete]
  end

  # SDK routes for dynamic loading of sdk with requirejs
  sdk_engine = Sprockets::Environment.new
  sdk_engine.append_path Rails.root.join('sdk/scripts').to_s
  mount sdk_engine, at: '/scripts'

  get '/current_version' => proc {  |env| [ 200, {'Content-Type' => 'text/plain', 'Content-Disposition' => 'inline'}, [File.read(Rails.root.join('REVISION'))] ] }
  get '/widgets/safari_fix', to: 'widgets#safari_fix'
  match '/widgets/contact', to: 'widgets#contact', as: :widgets_support, via: [:get, :post]
  get '/widgets/account_status', to: 'widgets#account_status'
  get '/widgets/login', to: 'widgets#login', as: :widgets_login
  post '/widgets/login', to: 'widgets#post_login'
  get '/widgets/register', to: 'widgets#register', as: :widgets_register
  post '/widgets/register', to: 'widgets#post_register'

  get '/profiles/:id/edit', to: 'redirects#edit_identity_by_pid'
  get '/contact', to: "application#contact", as: :support

  get '/sites/:id', to: 'redirects#edit_identity_by_site'

  class SDKConstraint
    def self.matches?(request)
      request.params[:_sdk].present?
    end
  end

  constraints SDKConstraint do
    match  "/oauth/status",       :to   => "oauth2_sdk#status", :as => :oauth_status, via: [:get, :post]
    get  "/oauth/authorize",       :to   => "oauth2_sdk#authorize", :as => :sdk_authorize
    post "/oauth/grant",           :to   => "oauth2_sdk#grant", :as => :sdk_post_oauth_grant
    get  "/oauth/grant",           :to   => "oauth2_sdk#grant", :as => :sdk_get_oauth_grant
    post "/oauth/deny",            :to   => "oauth2_sdk#deny", :as => :sdk_post_oauth_deny
    get  "/oauth/deny",            :to   => "oauth2_sdk#deny", :as => :sdk_get_oauth_deny
    post "/oauth/grant_or_deny",   :to   => "oauth2_sdk#grant_or_deny", :as => :sdk_post_oauth_grant_or_deny
    get  "/oauth/login",           :to   => "oauth2_sdk#login"
    get  '/oauth/choose_identity', :to   => "oauth2_sdk#choose_identity", as: :sdk_get_oauth_choose_identity
    match "/oauth/refresh_identity", :to => "oauth2_sdk#refresh_identity", :as => :sdk_post_oauth_refresh_identity, via: [:get, :post]
    get '/oauth/new_identity', :to       => 'oauth2_sdk#new_identity', as: :sdk_get_oauth_new_identity
  end

  # Default routes if not sdk
  get  "/oauth/authorize",       :to   => "oauth2#authorize", :as => :authorize
  post "/oauth/grant",           :to   => "oauth2#grant", :as => :post_oauth_grant
  get  "/oauth/grant",           :to   => "oauth2#grant", :as => :get_oauth_grant
  post "/oauth/deny",            :to   => "oauth2#deny", :as => :post_oauth_deny
  get  "/oauth/deny",            :to   => "oauth2#deny", :as => :get_oauth_deny
  post "/oauth/grant_or_deny",   :to   => "oauth2#grant_or_deny", :as => :post_oauth_grant_or_deny
  get  "/oauth/login",           :to   => "oauth2#login"
  get  '/oauth/choose_identity', :to   => "oauth2#choose_identity", as: :get_oauth_choose_identity
  match "/oauth/refresh_identity", :to => "oauth2#refresh_identity", :as => :post_oauth_refresh_identity, via: [:get, :post]
  get '/oauth/new_identity', :to       => 'oauth2#new_identity', as: :get_oauth_new_identity

  post '/oauth/token', :to => proc { |env| Idnet::Core::TokenEndpoint.new.call(env) }, as: :api_oauth2_token

  # for nginx/lua
  get '/file/attributes', to: 'documents#swift_attributes'
  post '/upload/swf/idnet-client', to: 'documents#upload_flash_sdk'

  resources :folders, only: [:create, :update]
  resources :documents, except: [:show, :destroy] do
    collection do
      put :update_parent, format: :json
      delete :destroy
    end
  end

  scope 'documents', defaults: {style: 'original'} do
    get 'view/:style/:id', to: 'documents#show', as: :view_document
    get 'download/:style/:id', to: 'documents#show', as: :download_document, defaults: {download: true}
    get 'certification/:id', to: 'documents#certification', as: :certification_document
  end

  get 'profile_pictures/:hash/:style(.:format)' => 'documents#show', as: :hash_document
  get 'games/thumbs/:hash/:style(.:format)' => 'documents#games', as: :hash_game

  if Rails.env.development?
    # Example pages for developement
    get '/ui' => "static_pages#ui"
    get '/textpage' => "static_pages#textpage"
  end

  # Checkout

  class CheckoutConstraints
    def self.matches?(request)
      %w(merchant_id amount currency usage transaction_id).all? do |field|
        request.params[field].present?
        # TODO output useful error instead of 404
      end
    end
  end

  get '/checkout', to: 'checkout#create', constraints: CheckoutConstraints
  put '/checkout/update', to: 'checkout#update'
  get '/checkout/cancel', to: 'checkout#cancel'

  # Static pages
  get 'about' => "static_pages#about", as: :about
  get 'privacy-policy' => "static_pages#privacy_policy", :as => :privacy_policy
  get 'cookie-policy' => "static_pages#cookie_policy", :as => :cookie_policy
  get 'terms-of-service' => "static_pages#terms_of_service", :as => :terms_of_service
  get '/app-center/terms-of-service' => "static_pages#terms_of_service_sdk", :as => :terms_of_service_sdk
  get 'help' => "static_pages#help", :as => :help

  # Gamecenter
  match "/tracking/active/:id", to: TrackingController.action(:track_active_player), via: [:post, :get]
  match "/tracking/view/:id", to: TrackingController.action(:track_view), via: [:post, :get]
  match "/refresh_data" => "apps#refresh_data", constraints: { subdomain: 'apps' }, as: :refresh_data, via: [:post, :get]
  get "/:id/(:embedded)" => 'canvas#show', constraints: { subdomain: 'apps', embedded: 'embedded' }, as: :canva

  # Validations
  post 'validations/verify' => 'validations#verify'

  # V2 identity profiles
  get 'profile2/:id', to: 'profile2#show', as: :profile2
  get 'profile2/external/:id', to: 'profile2#show_framed'


  unauthenticated :account do
    root :to => 'welcome#index'
  end

  authenticate :account do
    resource :email_notifications, to: [:edit, :update] do
      get 'email_notifications', to: 'email_notifications#edit', as: :email_notifications
    end

    get 'search' => 'search#index', as: :search

    get 'certifications' => redirect('/certification')
    resource :certification do
      root action: :index, as: 'root'
      post ':step', action: :update, as: :update
      get ':step' => :show, as: :step, constraints: -> req { req.params[:step].in? %w{information scan snapshot email}}
      get 'current-step', action: :current_step, as: :current_step
      get 'cell/number' => :cell_number
      get 'cell/code'   => :cell_code
      get 'cell/confirmed' => :cell_confirmed
      post 'cell/send'     => :cell_send
      post 'cell/confirm'  => :cell_confirm
      post 'cell/resend'   => :cell_resend
    end

    resource :confirmations, only: [] do
      collection do
        get 'choose_way'
        get 'confirm_by_mail'
        post 'confirm_by_mail' => :confirm_by_mail!

        get 'confirm_by_sms'
        post 'confirm_by_sms' => :confirm_by_sms!
        post 'resend_confirmation_instructions'
        post 'hide_email_confirmation_reminder'
      end
    end

    resources :trusted_devices, only: :destroy

    resources :applications do
      member do
        match 'achievements', via: [:post, :get], as: :achievements
        match 'achievements', via: [:delete], to: "applications#achievement_delete"
        match 'achievement_edit/:key', via: [:post, :get], to: "applications#achievement_edit", as: :achievement_edit
        post 'create_tracking'
        post 'create_hosting'
      end
      resources :scores, only: [:index, :destroy] do
        collection do
          delete :delete_all
        end
      end
      resources :playtomic_tables do
        collection do
          post :change_orders
          delete :delete_all
        end
        resources :playtomic_scores, only: [:index, :destroy] do
          collection do
            delete :delete_all
          end
        end
      end
    end

    get 'ads/management/content_owner', to: 'ads_management#content_owner'
    get 'ads/management/games', to: 'ads_management#games'
    post 'ads/management/content_owner', to: 'ads_management#update_content_owner'

    resources :identities do
      delete "unassociate/:client_id", to: "identities#unassociate", as: :unassociate
      post 'set_for/:client_id' => 'identities#reassign_client', as: :set
      collection do
        get 'visit'
        get 'choose'
        match 'select', via: [:get, :post]
      end
      member do
        get 'clients'
        put :set_as_default, as: :default
      end
    end

    resources :notifications, only: [:index]
  end

  namespace :dialogs do
    resources :app_requests, only: [:new, :create]
    resources :friends, only: [:new, :create]
    resources :feeds, only: [:new, :create]
    get "/leaderboard", to: "leaderboard#index"

    resource :certification do
      root action: :index, as: 'root'
      post ':step', action: :update, as: :update
      get ':step' => :show, as: :step, constraints: -> req { req.params[:step].in? %w{information scan snapshot email}}
      get 'current-step', action: :current_step, as: :current_step
    end
  end

  namespace :agents do
    resources :accounts
  end

  namespace :admin do
    get "/" => "accounts#index", :as => :main_dashboard

    get '/upload/swf/idnet-client', to: 'swc_uploader#new', as: :new_swc_uploader
    post '/upload/swf/idnet-client', to: 'swc_uploader#create', as: :swc_uploader

    match '/protection-lists', to: 'protection_lists#index', via: [:get, :post, :delete], as: :protection_lists

    resources :comments, only: [:index] do
      collection do
        post :spam_results
      end

      member do
        put :spam
        put :ham
      end
    end

    resources :authorizations, only: [:destroy, :index] do
      member do
        delete "delete", to: "authorizations#delete!", as: :delete
        get "restore", to: "authorizations#restore!", as: :restore
      end
    end

    authenticate :account, lambda { |u| u.admin? } do
      mount Resque::Server, at: "/pool", as: 'resque_pool'
      mount Sidekiq::Web, at: '/sidekiq', as: 'sidekiq'
    end

    resources :certifications, only: [:index, :show, :update] do
      collection do
        get :pending
      end
    end

    resources :profile_pictures, only: [:index] do
      put :review, on: :collection
    end
    resources :clients do
      member do
        post :accept
        post :reject
        match 'achievements', via: [:post, :get], to: "clients#achievements", as: :achievements
        delete 'achievements', via: [:delete], to: "clients#achievement_delete", as: :achievement_delete
      end
      collection do
        get :pending
      end
      resources :scores, only: [:index, :destroy] do
        collection do
          delete :delete_all
        end
      end
      resources :playtomic_tables do
        collection do
          post :change_orders
          delete :delete_all
        end
        resources :playtomic_scores, only: [:index, :destroy] do
          collection do
            delete :delete_all
          end
        end
      end
    end
    resources :agents

    resources :accounts do
      collection do
        get :admins
        post :allow_all, to: "accounts#allow_all"
      end

      member do
        get "confirm", to: "accounts#confirm"
        get "has_evidence"
        get "get_evidence_details/:device_id" => "accounts#get_evidence_details", as: :get_evidence_details
        put "add_evidence"
        put "retract_evidence/:evidence_type" => "accounts#retract_evidence", as: :retract_evidence

        put :send_confirmation_sms
        put :send_trust_sms
        put :send_confirmation_email
        put :send_password_reset_email

        get 'validate'
      end
    end

    resources :sms_logs, only: [:index]

    resources :transactions, only: [:index, :show] do
      member do
        put :allow
        put :deny
        put :report
      end
      collection do
        get :review
        get :unlock
        get :same_ip
      end
    end

    namespace :analytics do
      get "sms"
      get "sms_by_gateway", action: "sms_by_gateway", as: :sms_by_gateway
      get "sms_by_country", action: "sms_by_country", as: :sms_by_country
      get "sms_by_gateway_and_country", action: "sms_by_gateway_and_country", as: :sms_by_gateway_and_country
    end
    get "logs/sms", to: "logs#sms"

    resources :games, only: [:edit, :update, :destroy]

    scope '/games' do
      scope '/(:game_id)', game_id: nil do
        resources :videos, only: [:index, :create, :destroy]
      end
    end
  end

  # Popup or link based API
  scope module: 'idnet/api', path: 'api' do
    # Legacy api for profile
    get "profile", to: "profile#show"

    post "login", to: "auth#login"
    get "show", to: "auth#show"
    get "external/show", to: "auth#show_by_external_session"

    post "register", to: "auth#register"

    #
    # API based on Session authentication
    #
    resource :user_data do
      collection do
        post :login, to: "auth#login"
        match :autologin, to: "auth#autologin", via: [:post, :get]
        post :submit
        post :remove
        post :retrieve
        post :register, to: "auth#register"
        post :detect, to: "auth#show"
        post 'profile2/appimage', to: 'profile2_session#app_image', as: :app_image
        post 'profile2/show', to: 'profile2_session#show'
      end
    end

    resource :score, only: [:show, :create, :destroy]
    resources :scores, only: [:index, :show, :destroy]
    resources :leaderboard, only: [:index]

    #
    # API based on OAuth authentication
    # Compatible with JS SDK
    #
    scope "v1" do
      scope ':format' do
        get 'profile', to: 'profile#show', as: :api_v1_profile
      end
    end


    namespace :v1 do
      scope ":format" do
        # Friends
        scope 'links' do
          %w{unfollow follow accept block unblock mutual_accept}.each do |action|
            post "#{action}/:id" => "friends##{action}"
          end
          %w{friends followers followees blocked pending}.each do |action|
            get action => "friends##{action}"
          end
        end

        # Identities
        get "identity" => "identities#show"
        post "identity" => "identities#update"
        get "identity/real" => "identities#real"

        post 'profile2/appimage', to: 'profile2_auth#app_image'

        post 'chat/list_friends', to: 'chat#list_friends'

        get 'protection-lists', to: 'protection_lists#index', as: :protection_lists_api

        post 'user_data/submit', to: 'user_data_auth#submit'
        post 'user_data/remove', to: 'user_data_auth#remove'
        post 'user_data/retrieve', to: 'user_data_auth#retrieve'

        # Site comments
        # FIXME: Keeping :activities for compatibility. Think about deprecation process
        resources :activities, only: [:index, :create], controller: :site_comments

        constraints format: 'json' do
          # Scores
          resource :user_score, only: [:show, :create, :destroy]
          resources :user_scores, only: [:index, :show, :destroy]
          post 'user_scores/:id' => 'user_scores#create'
          delete 'application_scores' => 'application_scores#destroy'
          get 'application_scores' => 'application_scores#index'
          get 'related_users/:authorization_id' => 'related_users#index', as: :related_users
          get 'leaderboard' => 'leaderboard#index'
        end

        # Analytics auth
        get 'account/role' => 'accounts#role'
        get 'account/applications' => 'accounts#applications'

        get 'tracking/game_names' => 'tracking#game_names'
        get 'tracking/exclusions' => 'tracking#exclusions'

        get 'tracking/get_uuid' => 'tracking#get_uuid'
        post 'tracking/set_uuid' => 'tracking#set_uuid'
        get 'tracking/get_token' => 'tracking#get_token'
        get 'tracking/get_token_via_session' => 'tracking#get_token_via_session'

        resources :accounts, only: [:create, :update]
        resources :app_feeds, only: [:create, :destroy]
        resources :orders, only: [:show, :update] do
          get :checkout_token, on: :member
        end

        # Graph API

        # Friends
        get ':id/friends'   => "friends#graph_friends"
        get ':id/friends-all'   => "friends#friends_all"
        get ':id/followers' => "friends#graph_followers"

        # Application Requests
        get    'request-:id' => "application_requests#show"
        delete 'request-:id' => "application_requests#destroy"
      end
      resources :accounts, only: [:create]

      resource :leaderboard, only: [:update] do
        collection do
          post :submit, to: "leaderboard#update"
        end
      end
    end
  end

  authenticate :account do
    # SCOPED BY IDENTITY
    # These should be the last routes
    scope '/(:scope_id)', scope_id: nil do
      resource :profile_picture
      resources :friends, only: :index, path: 'contacts' do
        collection do
          get 'followers'
          get 'following'
          get 'blocked'
          get 'pending'
        end

        member do
          post 'accept'
          post 'block'
          post 'unblock'
          post 'follow'
          post 'unfollow'
          post 'add_as_friend', as: :add_as
        end
      end

      get "mail_link/accept_friend/:id" => 'friends#add_as_friend', as: :mail_accept_friend

      resources :conversations do
        get 'new/:recipient_id' => 'conversations#new', on: :collection, as: :new
        post 'new/:recipient_id' => 'conversations#create', on: :collection

        delete 'delete' => 'conversations#delete', on: :collection
        match 'delete_message/:message_id' => 'conversations#delete_message', via: [:delete],
          as: :delete_message, on: :member
      end

      resources :feeds, only: [:index, :create, :show] do
        member do
          get 'redirect', as: :redirect
          delete 'trash', as: :trash
          delete 'delete_comment/:comment_id', action: :delete_comment, as: :delete_comment
          post 'comment', as: :comment
        end
      end
      # Leave this at the end of routes
      root :to => "identities#index", as: :authenticated_root
    end
  end

  resource :monitoring, controller: 'monitoring' do
    get :check_redis
    get :check_elasticsearch
    get :check_mysql
    get :check_mongodb
    get :check_memcached
    get :check_all
  end

  match '*path', to: 'pages#not_found', via: [:get, :post]
end
