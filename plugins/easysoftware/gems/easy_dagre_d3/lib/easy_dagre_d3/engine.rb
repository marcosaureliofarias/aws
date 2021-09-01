require 'rys'

module EasyDagreD3
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_dagre_d3'
  
    initializer 'easy_dagre_d3.setup' do
      # Custom initializer
    end
  end
end
