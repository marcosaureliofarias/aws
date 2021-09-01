require 'rys'

module SecurityUserLock
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'security_user_lock'

    initializer 'security_user_lock.setup' do
      # Custom initializer
    end

  end
end
