require 'rspec/rails'
require 'easy_extensions/spec_helper'
require 'capybara/rspec'
class JavaScriptError < StandardError;
end

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)


# warning supress for ruby 2.0 and new capybara see https://gist.github.com/ericboehs/7125105
class WarningSuppressor
  IGNORES = [
      /QFont::setPixelSize: Pixel size <= 0/,
      /CoreText performance note:/,
      /Heya! This page is using wysihtml5/,
      /You must provide a success callback to the Chooser to see the files that the user selects/
  ]

  class << self
    def write(message)
      if suppress?(message) then
        0
      else
        puts(message); 1;
      end
    end

    private

    def suppress?(message)
      IGNORES.any? { |re| re.match?(message) }
    end
  end
end

# Capybara.ignore_hidden_elements = false

RESOLUTION = ENV['RESOLUTION'].to_s.split(',').presence || [1920, 1080]
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

Capybara.register_driver :chrome do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: ENV['CHROME_OPTIONS'].to_s.split(' '))
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

Capybara.javascript_driver     = ENV['JS_DRIVER'].present? ? ENV['JS_DRIVER'].downcase.to_sym : :chrome
Capybara.default_max_wait_time = 8

# TODO: write own!
#ActiveRecord::Migration.maintain_test_schema!

def persistant_tables
  EasyExtensions::Tests::EasyTestPrepare.persist_tables
end

ActionMailer::Base.delivery_method = :test
ActiveJob::Base.queue_adapter      = :test

SCREENSHOT_DIR = "#{Rails.root}/tmp/failed_screenshots"
STRATEGY       = ENV['STRATEGY'].presence

RSpec.configure do |config|
  while config.requires.any?
    require config.requires.pop
  end
  # config.requires.each {|f| require f }
  config.include ActionView::Helpers::NumberHelper
  config.include ActiveSupport::Testing::TimeHelpers

  # config.backtrace_exclusion_patterns = []
  config.default_path                         = 'plugins/easyproject/easy_plugins/easy_extensions/spec'
  config.example_status_persistence_file_path = 'tmp/test/examples.txt'
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :flexmock
  # config.mock_with :rr
  # config.mock_with :mocha

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/plugins/easyproject/easy_plugins/easy_extensions/test/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'defined:1'

  config.infer_spec_type_from_file_location!

  config.define_derived_metadata(file_path: Regexp.new('/spec/libs/')) do |metadata|
    metadata[:type] = :lib
  end

  config.expose_current_running_example_as :example

  # rspec-retry config
  config.verbose_retry                = true
  config.display_try_failure_messages = true
  config.default_retry_count          = 1
  config.default_sleep_interval       = 1

  config.before(:suite) do
    # easy_test_prepare should handle this
    # DatabaseCleaner.strategy = :deletion
    # DatabaseCleaner.clean_with(:truncation, except: persistant_tables)
    # EasyExtensions::Tests::EasyTestPrepare.prepare!
    if STRATEGY == 'transaction'
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :deletion, { except: persistant_tables }
    end

    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
    Setting.login_required    = '1'
    Setting.text_formatting   = 'none'
    Rails.cache.clear if ENV['CLEAR_CACHE'].present?

    FileUtils.rm_rf(SCREENSHOT_DIR)
    puts "Screenshots: #{SCREENSHOT_DIR}"
  end

  config.before(:each, :js => true) do
    skip "can't run inside a transaction" if STRATEGY == 'transaction'
    #page.driver.reset!
    Capybara.reset_sessions!
    #page.driver.browser.manage.window.resize_to(*RESOLUTION) if page.driver.browser.respond_to?(:manage)
  end

  config.before(:each, :deletion => true) do
    skip "can't run inside a transaction" if STRATEGY == 'transaction'
  end

  config.before(:all, :null => true) do
    DatabaseCleaner.strategy = DatabaseCleaner::NullStrategy
  end

  config.after(:all, :null => true) do
    DatabaseCleaner.strategy = :deletion, { except: persistant_tables }
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :transaction if STRATEGY == 'transaction'
  end

  config.before(:all, with_hidden_elements: true) do
    Capybara.ignore_hidden_elements = false
  end

  config.after(:all, with_hidden_elements: true) do
    Capybara.ignore_hidden_elements = true
  end

  config.before(:each, :without_cache => true) do
    Rails.cache.clear
  end

  config.before(:each) do
    DatabaseCleaner.start
    RequestStore.clear! # invalidates cache
  end

  config.around(:each) do |ex|
    meta = ex.metadata
    if (opts = EasyExtensions::Tests::AllowedFailures.test_names[meta[:full_description]])
      pending(opts[:message].to_s)
      raise unless opts[:raise] == false
    end
    ex.run
  end

  config.before(:each) do |ex|
    meta = ex.metadata

    unless meta[:null]
      EasyExtensions::Tests::EasyTestPrepare.load_default_fixtures

      logged_user case meta[:logged]
                  when :admin
                    FactoryGirl.create(:admin_user, language: 'en')
                  when true
                    FactoryGirl.create(:user, language: 'en')
                  else
                    User.anonymous
                  end
    end
  end

  config.before(:all, js_wait: :long) do
    @default_wait_time_backup      = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 30
  end

  config.after(:all, js_wait: :long) do
    Capybara.default_max_wait_time = @default_wait_time_backup
  end

  config.after(:each, js: true) do
    if Capybara.javascript_driver == :chrome
      errors = page.driver.browser.manage.logs.get(:browser).
          select { |e| e.level == "SEVERE" && e.message.present? }.map(&:message).to_a

      warnings, errors = errors.partition { |e| e.include?('Failed to load resource') }
      puts "Warning: #{warnings.join("\n\n")}" if warnings.present?
      raise JavaScriptError, errors.join("\n\n") if errors.present?
    end
  end

  config.after(:each, js: true) do |example|
    if example.exception.present?
      FileUtils.mkdir_p(SCREENSHOT_DIR) unless File.exists?(SCREENSHOT_DIR)
      meta            = example.metadata
      filename        = File.basename(meta[:file_path])
      line_number     = meta[:line_number]
      screenshot_name = "failure-#{filename}-L#{line_number}-#{SecureRandom.hex}.png"
      screenshot_path = "#{SCREENSHOT_DIR}/#{screenshot_name}"
      page.save_screenshot(screenshot_path)
    end

  end

  config.around :each, js: true do |ex|
    ex.run_with_retry retry: 3
  end

  config.append_after(:each) do
    EasyJob.wait_for_all
    DatabaseCleaner.clean
  end

  config.after(:each) do
    ActiveJob::Base.queue_adapter = :test
  end
end
