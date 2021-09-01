class EasySsoLoginController < AccountController

  layout 'sso_login'

  def sso_login
    if request.post?
      authenticate_user
    else
      if User.current.logged?
        successful_authentication_redirect_url(User.current) || redirect_to(home_url) #redirect_back_or_default(home_url, :referer => true)
      end
    end
  rescue AuthSourceException => e
    logger.error "An error occurred when authenticating #{params[:username]}: #{e.message}"
    render_error :message => e.message
  end

end
