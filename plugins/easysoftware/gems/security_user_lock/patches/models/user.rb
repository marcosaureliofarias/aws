Rys::Patcher.add('User') do

  included do
    def self.locking_time
      if EasySetting.value('user_locking_time') && EasySetting.value('user_login_period')
        EasySetting.value('user_locking_time').to_i.send(EasySetting.value('user_login_period'))
      else
        1.hour
      end
    end
  end

  class_methods(feature: 'security_user_lock') do

    def try_to_login(login, password, *args)
      user = super
      u = find_by_login(login)

      if u&.active? && u.check_password?(password) && u.failed_login_attempts != 0
        u.update_columns(blocked_at: nil, failed_login_attempts: 0)
      end

      user
    end

  end

end
