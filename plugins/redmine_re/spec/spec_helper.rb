require "easy_extensions/spec_helper"
require "simplecov"
SimpleCov.start "rails"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

['factories'].each do |dir|
  Dir[File.join(__dir__, "#{dir}/**/*.rb")].each { |f| require f unless f =~ /^_/ }
end
