require 'rys'

module Easy
  module Redmine
    class Engine < ::Rails::Engine
      include Rys::EngineExtensions
    
      rys_id 'easy_redmine'
    
      initializer 'easy_redmine.setup' do
        # Custom initializer
      end
    end
  end
end
