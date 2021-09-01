require 'rys'

module EasyD3
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_d3'
  
    initializer 'easy_d3.setup' do
      # Custom initializer
    end
  end
end
