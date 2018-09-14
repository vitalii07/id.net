# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'factory_girl'
require 'capybara/rspec'
require 'capybara/rails'
require 'rspec/rails'
require 'webmock/rspec'
require 'mongoid-rspec'
require 'database_cleaner'
require 'devise'

# allow connection to ES on initialization
WebMock.disable_net_connect! allow_localhost: true


current_config = Rails.application.config.database_configuration[Rails.env]
ActiveRecord::Base.establish_connection(current_config)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
DatabaseCleaner[:active_record].strategy = :truncation
DatabaseCleaner[:mongoid].strategy = :truncation
# DatabaseCleaner.orm = :mongoid
DatabaseCleaner.logger = Rails.logger

unless RUBY_PLATFORM =~ %r{darwin}
  require 'headless'
  headless = Headless.new reuse: true
  headless.start
end

if defined? Paperclip
  Paperclip::Attachment.default_options[:storage] = :filesystem
  if File.directory?("/tmp") && File.writable?("/tmp")
    Paperclip::Attachment.default_options[:path] = "/tmp/idnet-specs/:url"
  end
end


Capybara.default_wait_time = 3
Capybara.ignore_hidden_elements = false

RSpec.configure do |config|
  config.include ActionDispatch::TestProcess
  config.include Capybara::DSL
  config.include Mongoid::Matchers
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, :type => :controller
  config.include Warden::Test::Helpers, :type => :request
  config.include AuthenticationSupport, :type => :request
  config.include ElasticSearchSupport
  config.include OtherHelpers
  config.include OAuthHelper

  config.filter_run :focus => true
  config.filter_run_excluding :broken => true

  config.infer_spec_type_from_file_location!

  config.run_all_when_everything_filtered = true
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  #config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  # config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"


  config.before :suite  do
    DatabaseCleaner.clean
    FileUtils.rm_rf File.join(Rails.public_path, 'test-files')
    Warden.test_reset! if Warden.respond_to? :test_reset!
  end

  config.before :each, type: :request do
    Capybara.default_host = 'http://' + Rails.application.default_url_options[:host]
  end



  config.before(:each) do |example|
    WebMock.disable_net_connect! allow_localhost: true

    ::Capybara.reset_sessions!
    DatabaseCleaner[:mongoid].start unless example.metadata[:no_mongo]
    DatabaseCleaner[:active_record].start if example.metadata[:active_record]
    reset_email
  end

  config.before :each, type: :controller do |example|
    allow_any_instance_of(described_class).to receive(:redirect_untrusted_devices) unless example.metadata[:trust_device]
  end

  # Turn off :redirect_untrusted_devices before_filter in Request specs
  config.around :each, type: :request do |example|
    # Stubbing method manually because Mocha can't stub method on any_instance
    # of any subclass. Can't use ApplicationController.descendants and stub
    # any_instance of descendant because ApplicationController.descendants is
    # not consistent when using Zues.
    ApplicationController.send :alias_method, :old_redirect_untrusted_devices, :redirect_untrusted_devices
    ApplicationController.send :define_method, :redirect_untrusted_devices do; end
    example.run
    ApplicationController.send :alias_method, :redirect_untrusted_devices, :old_redirect_untrusted_devices
  end

  config.after(:each) do |example|
    DatabaseCleaner[:mongoid].clean unless example.metadata[:no_mongo]
    DatabaseCleaner[:active_record].clean if example.metadata[:active_record]
  end

  config.after :each, type: :request do
    Warden.test_reset!
  end
end
