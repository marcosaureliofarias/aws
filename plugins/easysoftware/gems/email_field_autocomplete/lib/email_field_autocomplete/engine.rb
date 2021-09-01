require 'rys'

module EmailFieldAutocomplete
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'email_field_autocomplete'
  
    initializer 'email_field_autocomplete.setup' do
      # Custom initializer
    end
  end
end
