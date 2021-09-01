require 'rys'

module ExtendedUsersContextMenu
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'extended_users_context_menu'

    initializer 'extended_users_context_menu.setup' do
      # Custom initializer
    end

  end
end
