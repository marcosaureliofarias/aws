require 'rys'

module DependentListCustomField
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'dependent_list_custom_field'

    initializer 'dependent_list_custom_field.setup' do
      # Custom initializer
    end

  end
end
