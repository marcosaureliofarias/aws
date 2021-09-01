RSpec.configure do |_config|
  require 'easy_extensions/spec_helper'
  _config.include Features::EasySchedulerEntityModalHelpers, type: :feature
end
