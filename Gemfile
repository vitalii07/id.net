# -*- RUBY -*-
source 'https://rubygems.org'

# CORE

# Rails framework
gem 'rails', '~> 4.2.3'
# Rails translation
gem 'rails-i18n'
# MongoDB model mapping
gem 'mongoid', '~> 4.0.2'
gem 'moped', '~> 2.0.7'
# MySQL database is used in Checkouts
gem 'mysql2'
# OAuth2 provider, id.net own fork nov/rack-oauth2
gem 'rack-oauth2', github: 'idnet/rack-oauth2'
# CORS for Ajax with xd_handler
gem 'rack-cors', require: 'rack/cors'

gem 'protected_attributes'

gem 'actionpack-action_caching'

# Settings

gem 'settingslogic'

# DATABASE EXTENSIONS

# Mongoid observers removed in 4.x
gem 'mongoid-observers'
# Rails migrations support for mongoid
gem 'mongoid_rails_migrations', '~> 1.0.1'
# Slug is used to make unique URLs to applications from name parameter
gem 'mongoid-slug' , '~> 4.0.0'
# Control model history of modifications
gem 'mongoid-audit'
# Storing files in models
gem 'paperclip'
# Paperclip mongoid support
gem 'mongoid-paperclip', require: 'mongoid_paperclip'
# Mongoid::Paranoid removed in mongoid 4.x
gem 'mongoid-paranoia'
gem 'mongoid-sadstory'

# Cloud computing for swift
gem 'fog', require: 'fog/openstack'

# Moving to carrierwave instead of paperclip
# Separate uploader class instead of embedded methods like paperclip_processors
gem 'mini_magick'
gem 'carrierwave'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'carrierwave-video'
gem 'carrierwave-video-thumbnailer'
gem 'streamio-ffmpeg'
gem 'carrierwave_backgrounder'

# SCHEDULING AND AUTOMATION

# Background task dispatcher
gem 'resque', '~> 1.25.2', require: 'resque/server'
gem 'sidekiq', '~> 3.4.2'

# Asynchronous mail for resque
gem 'resque_mailer', '~> 2.2.6'
# Tab layout for resque admin
gem 'resque-tabber', '~> 0.0.1'
# Delay/schedule for resque tasks
gem 'resque-scheduler', '~> 4.0.0', require: false
# Memcached client
gem 'dalli'

# Pagination
# require it before any elasticsearch gem
gem 'kaminari'

# Elasticsearch client
gem 'elasticsearch-model', github: 'hallelujah/elasticsearch-rails'
gem 'elasticsearch-rails', github: 'hallelujah/elasticsearch-rails'
# Key-value db client for resque and sms
gem 'redis', '~> 3.2.1'

# Redis bitmap metrics tool
# Minuteman is broken after 1.0.3, at least in combination with redis-namespace
gem 'minuteman', github: 'idnet/minuteman', branch: 'update_gems_1.0.3'

# keep application's heap from being copied when forking command line processes
gem 'posix-spawn'

# EXTERNAL SERVICES

# phraseapp translations
gem 'phrase'
# Querying SOAP API for Iovation
gem 'savon', '~>1.2.0'
# Geolocalization to define where request came from
gem 'geoip'
# Client API for Akismet spam service
gem 'rakismet', '~> 1.3.0'
# SMS sending detached workers
group :sms_worker do
  gem 'mollie-sms', require: false
  gem 'twilio-ruby', require: false
  gem 'nexmo', require: false
end

# Statsd client for stats.helios.me
gem 'statsd-ruby', '~> 1.2.1'

# MODEL EXTENSIONS

# Authentication
gem 'devise', '~> 3.5'
# Asynchronous mail for devise
gem 'devise-async'
# Authorization and managing user rights
gem 'cancancan', '~> 1.10'
# State machine
gem 'state_machine', '~> 1.2.0'
# Phone numbers format validation
gem 'global_phone'
# Generate file with numbers validators
gem 'global_phone_dbgen', require: false
# Country list
gem 'carmen', '1.0.2'
# Country list engine
gem 'carmen-rails', '~>1.0.1'
# Email validations
gem 'valid_email', require: ['valid_email/email_validator']
# valid_email breaks with mail 2.6 => Mail::Address.tree no longer exists
gem 'mail', '< 2.6'

# FRONT-END

# Javascript translation TODO try to remove this or integrate with ruby i18n
gem 'i18n-js', github: 'fnando/i18n-js', ref: 'f67fa51427dd004b43f20c46c4016a71012d6699'
# HTML Meta-tags
gem 'meta-tags', :require => 'meta_tags'

# ADDITIONAL

# Detecting language from request
gem 'http_accept_language', require: 'http_accept_language/parser'
# HMAC signature
gem 'hsign', '~> 0.0.2', require: 'hsign/digest'
# Decision table for sending sms
gem 'rufus-decision'
# Template for JSON/XML in API output
gem 'rabl'
# JSON parser
gem 'oj'
# JSON parser agnostic wrapper
gem 'multi_json', '~> 1.5.1'

# Timeout when request takes too long
gem 'rack-timeout', require: false

gem 'rails-html-sanitizer'

# Payment provider
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'

gem 'sass-rails', '5.0.1'
gem 'compass', '1.0.3'
gem 'compass-rails', '2.0.4'

gem 'uglifier'                  # Making JS unreadable
gem 'jquery-rails'              # JQuery
gem 'execjs'                    # Run JS from Ruby
gem 'therubyracer'              # Run JS from Ruby and Ruby from JS
gem 'zurb-foundation', '3.2.5'  # Zurb Framework integration
gem 'ejs'                       # EJS templates compilation

# DEPRECATE IT! 24/04/14
gem 'coffee-rails', '~> 4.1.0'

group :development do
  gem 'mail_view'     # Previewing emails
  gem 'thin'          # HTTP Server
  gem 'quiet_assets'  # Disable server output on assets
  gem 'letter_opener' # When server sends email - it opens browser instead
  gem 'better_errors' # Error logging during server errors
  gem 'fontello_rails_converter', require: false # Convert icons to font

  # Deployment gems
  gem 'capistrano', '~> 3.4'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-rbenv', '~> 2.0'
  gem 'capistrano-rbenv-install', '~> 1.2.0'
end

group :development, :test, :staging do
  gem 'minitest'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'rspec_junit_formatter'
  gem 'color-logger'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-nav'
  #gem 'pry-byebug', platforms: [:ruby_20, :ruby_21]
  gem 'pry-stack_explorer'
  gem 'factory_girl_rails'
  gem 'forgery'
end

group :test do
  gem 'headless'            # Run tests without a browser in Linux
  gem 'capybara', '~> 2.4.4'  # Integration DSL
  gem 'database_cleaner'    # Clean DB after every test
  gem 'mongoid-rspec', '~> 2.1.0'     # Mongoid related spec helpers
  gem 'ci_reporter_rspec'           # Reporting specs status
  gem 'launchy'                     # Launch a browser for Selenium
  gem 'timecop'                     # Mockings time
  gem 'webmock', require: false     # Mock external requests
  gem 'selenium-webdriver'          # Selenium
  gem 'fuubar'                      # Rspec formatter
end

group :production, :staging do
  # Process monitoring
  gem 'bluepill', '~> 0.0.69'
  # Process monitoring, replacement for bluepill. Github due to dependency clash with sidekiq
  gem 'eye', github: 'kostya/eye', ref: '1016fa7fe47088815f26c596aee282baf58d1d0e'
  # Logging
  gem 'gelf'
  gem 'airbrake-graylog2'
end

group :production do
  # Cron updater
  gem 'whenever', require: false
  # HTTP server
  gem 'unicorn'
  # Server metrics
  gem 'newrelic_rpm'
  # Server database metrics
  gem 'newrelic_moped'
end
