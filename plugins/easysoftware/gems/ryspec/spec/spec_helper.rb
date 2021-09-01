$ryspec = true
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter %r{^/lib/.+?/version\.rb}
end
require_relative 'init_rails'

require 'rspec/rails'
require 'capybara/rspec'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

RYSPEC_PERSISTANT_TABLES = %w(settings easy_settings trackers enumerations issue_statuses rys_features ar_internal_metadata)
RESOLUTION = ENV['RESOLUTION'].to_s.split(',').presence || [1920, 1080]
JS_DRIVER = ENV['JS_DRIVER'].present? ? ENV['JS_DRIVER'].downcase.to_sym : :chrome_headless
CHROME_OPTIONS = ENV['CHROME_OPTIONS'].to_s.split(' ')

require_relative 'init_factory_bot'
require_relative 'init_capybara'
require_relative 'init_support'

require 'database_cleaner'

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|

  config.include Ryspec::Test::Rys
  config.include Ryspec::Test::Users
  config.include Ryspec::Test::Settings

  # Enables zero monkey patching mode for RSpec.
  config.disable_monkey_patching!

  config.infer_spec_type_from_file_location!

  # # Sets the expectation framework module(s) to be included in each example group.
  # config.expect_with :rspec do |expectations|
  #   expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  # endS

  # # Sets the mock framework adapter module.
  # config.mock_with :rspec do |mocks|
  #   mocks.verify_partial_doubles = true
  # end

  # # Configures how RSpec treats metadata passed as part of a shared example group definition.
  # config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: RYSPEC_PERSISTANT_TABLES)
    DatabaseCleaner.strategy = :transaction
  end

  config.prepend_before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
    RequestStore.clear!
  end

  config.before(:each, :logged) do |example|
    logged_user case example.metadata[:logged]
                when :admin
                  User.find_by(admin: true) || FactoryBot.create(:user, :admin)
                when :user, true
                  User.active.first || FactoryBot.create(:user)
                else
                  User.anonymous
                end
  end

  config.after(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

end
