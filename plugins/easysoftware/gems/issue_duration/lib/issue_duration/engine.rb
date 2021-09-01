require 'rys'

module IssueDuration
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'issue_duration'

    initializer 'issue_duration.setup' do
      # Custom initializer
    end

  end
end
