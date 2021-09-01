# require 'bundler'
#
# spec = Bundler.load.specs.find{|s| s.name.to_s == 'easy_core' }
#
# if !spec
#   abort('Gem easy_core was not found. Please add it and run bundle install again.')
# end
#
# require File.join(spec.full_gem_path, 'spec/spec_helper')

ENV["RAILS_ENV"] = "test"
require "simplecov"
SimpleCov.start "rails" do
  add_filter "lib/easy_monitoring/version.rb"
end

require "bundler/setup"
# require "webmock/rspec"

require_relative "../test/dummy/config/environment"

require "rspec/rails"
# require "active_resource_response/http_mock"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end