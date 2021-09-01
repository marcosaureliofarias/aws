class EasyOauth2CallbacksController < AccountController

  def easy_oauth2_applications
    @oauth_application  = EasyOauth2ClientApplication.active.find_by(guid: params[:guid])
    @oauth_data         = request.env['omniauth.auth']
    @oauth_data['info'] ||= {}

    if @oauth_application.nil?
      render_error status: 422, message: I18n.t(:alert_sso_application_not_found)
      return
    end

    if params[:oauth2_action] == 'authorization'
      authorization_callback
    else
      login_callback
    end
  end

  private

  def authorization_callback
    access_token             = EasyOauth2Token.access_token(@oauth_application)
    access_token.value       = @oauth_data['credentials']['token']
    access_token.valid_until = @oauth_data['credentials']['expires'] && Time.at(@oauth_data['credentials']['expires_at'])
    access_token.save

    refresh_token       = EasyOauth2Token.refresh_token(@oauth_application)
    refresh_token.value = @oauth_data['credentials']['refresh_token']
    refresh_token.save

    if access_token.changed?
      flash[:error] = I18n.t(:error_easy_oauth2_cannot_save_access_token)
    elsif refresh_token.changed?
      flash[:error] = I18n.t(:error_easy_oauth2_cannot_save_refresh_token)
    else
      flash[:notice] = I18n.t(:notice_easy_oauth2_access_granted)
    end

    redirect_to easy_oauth2_application_path(@oauth_application)
  end

  def login_callback
    user = find_user_from_oauth_data

    if user.nil?
      if @oauth_application.onthefly_creation?
        user                 = User.new
        user.mail            = @oauth_data['info']['email']
        user.login           = @oauth_data['info']['nickname']
        user.firstname       = @oauth_data['info']['first_name']
        user.lastname        = @oauth_data['info']['last_name']
        user.sso_provider    = @oauth_data.provider
        user.sso_uuid        = @oauth_data['info']['sso_uuid']
        user.easy_avatar_url = @oauth_data['info']['image']
        user.language        = @oauth_data['info']['locale']
        user.random_password
        user.register

        register_automatically(user) do
          onthefly_creation_failed(user)
        end
      else
        render_error status: 422, message: "Cannot create new user, because on the fly creation is disabled."
      end

      return
    end

    if user.active?
      session[:sso]                   = {}
      session[:sso][:sso_provider]    = @oauth_data.provider
      session[:sso][:sso_uuid]        = @oauth_data['info']['sso_uuid']
      session[:sso][:email]           = @oauth_data['info']['email']
      session[:sso][:easy_avatar_url] = @oauth_data['info']['image']

      user.update_last_login_on! if !user.new_record?
      successful_authentication(user)
      update_sudo_timestamp! # activate Sudo Mode
    else
      handle_inactive_user(user)
    end
  end

  def find_user_from_oauth_data
    case @oauth_application.user_identifier_attribute
    when 'mail'
      User.joins(:email_addresses).where(email_addresses: { address: @oauth_data['info']['email'] }).first
    when 'login'
      User.find_by(login: @oauth_data['info']['nickname'])
    end
  end

end
