require 'rys'

module SearchInAdministration
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'search_in_administration'

    initializer 'search_in_administration.setup' do
      # Custom initializer
    end

  end
end
