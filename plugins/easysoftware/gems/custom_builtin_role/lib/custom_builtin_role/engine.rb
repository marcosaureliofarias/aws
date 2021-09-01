require 'rys'

module CustomBuiltinRole
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'custom_builtin_role'
  
    initializer 'custom_builtin_role.setup' do
      # Custom initializer
    end
  end
end
