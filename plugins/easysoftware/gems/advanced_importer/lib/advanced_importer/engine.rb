require 'rys'

module AdvancedImporter
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'advanced_importer'

    initializer 'advanced_importer.setup' do
      # Custom initializer
    end

  end
end
