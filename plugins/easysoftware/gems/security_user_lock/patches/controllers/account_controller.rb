Rys::Patcher.add('AccountController') do

  included do
  end

  instance_methods do
  end


  instance_methods(feature: 'security_user_lock') do

    def password_authentication
      user = User.find_by_login(params[:username].to_s.strip)
      locking_time = User.locking_time

      if user&.blocked_at && (locking_time == 0 || (user.blocked_at + locking_time) > Time.now)
        flash.now[:error] = EasySetting.value('message_to_locked_user').presence || l('security_user_lock.default_message_for_blocked_users')
      elsif user&.active? && !user.check_password?(params[:password])
        user.update_column(:failed_login_attempts, user.failed_login_attempts + 1)
        login_attempts = EasySetting.value('user_login_attempts').to_i
        if login_attempts != 0 && user.failed_login_attempts >= login_attempts
          user.update_column(:blocked_at, Time.now)

          EasyLockNotifier.notify_admins(user, locking_time.to_i, remote_ip: request.remote_ip, browser: browser.name, device: browser.device.name, platform: browser.platform.name).deliver_later
          flash.now[:error] = EasySetting.value('message_to_locked_user').presence || l('security_user_lock.default_message_for_blocked_users')
        else
          invalid_credentials
        end
      else
        super
      end

    end

  end

end
