require 'rys'

module EasyComputedFieldFromQuery
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_computed_field_from_query'
  
    initializer 'easy_computed_field_from_query.setup' do
      if Redmine::Plugin.installed?(:easy_extensions)
        Dir[File.dirname(__FILE__) + '/field_formats/*.rb'].each {|file| require_dependency file }
      end
    end
  end
end
