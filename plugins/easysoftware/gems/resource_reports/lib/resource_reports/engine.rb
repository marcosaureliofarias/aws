require 'rys'

module ResourceReports
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'resource_reports'
  
    initializer 'resource_reports.setup' do
      # Custom initializer
    end
  end
end
