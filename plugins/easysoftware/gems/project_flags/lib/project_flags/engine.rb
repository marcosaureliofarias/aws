require 'rys'

module ProjectFlags
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'project_flags'

    initializer 'project_flags.setup' do
      # Custom initializer
    end

  end
end
