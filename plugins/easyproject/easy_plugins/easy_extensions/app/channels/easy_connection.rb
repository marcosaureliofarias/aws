class EasyConnection < ActionCable::Connection::Base

  identified_by :current_user

  def connect
    if user = find_verified_user
      self.current_user = user
      User.current      = user

      logger.add_tags 'ActionCable', self.current_user.login
    end
  end

  def disconnect
  end

  protected

  def autologin_cookie_name
    Redmine::Configuration['autologin_cookie_name'].presence || 'autologin'
  end

  def find_verified_user
    if request.session[:user_id]
      user = (User.active.find(request.session[:user_id]) rescue nil)
    elsif request.cookies[autologin_cookie_name] # && Setting.autologin?
      user = Token.find_active_user('autologin', request.cookies[autologin_cookie_name], Setting.autologin.to_i)
    end

    if !user
      reject_unauthorized_connection
    end

    user
  end

end
