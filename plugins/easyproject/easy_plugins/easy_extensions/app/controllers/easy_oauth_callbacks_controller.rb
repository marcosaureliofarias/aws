class EasyOauthCallbacksController < AccountController

  def sso_easysoftware_com
    auth = request.env['omniauth.auth']
    user = User.joins(:email_addresses).where(email_addresses: { address: auth.info.email }).first if auth.info && !auth.info.email.blank?
    user ||= User.find_or_initialize_by(sso_provider: auth.provider, sso_uuid: auth.uid)

    if user.new_record?
      if !Setting.self_registration?
        flash[:warning] = l(:notice_sso_need_login)

        session[:sso]                   = { sso_provider: auth.provider, sso_uuid: auth.uid }
        session[:sso][:email]           = auth.info.email if auth.info && !auth.info.email.blank?
        session[:sso][:easy_avatar_url] = auth.info.image if auth.info && !auth.info.image.blank?

        redirect_to(home_url)
        return
      end

      user.mail            = auth.info.email if auth.info && !auth.info.email.blank?
      user.firstname       = auth.info.first_name if auth.info && !auth.info.first_name.blank?
      user.lastname        = auth.info.last_name if auth.info && !auth.info.last_name.blank?
      user.sso_provider    = auth.provider
      user.sso_uuid        = auth.uid
      user.easy_avatar_url = auth.info.image if auth.info && !auth.info.image.blank?
      user.random_password
      user.register

      case Setting.self_registration
      when '1'
        register_by_email_activation(user) do
          onthefly_creation_failed(user)
        end
      when '3'
        register_automatically(user) do
          onthefly_creation_failed(user)
        end
      else
        register_manually_by_administrator(user) do
          onthefly_creation_failed(user)
        end
      end
    else
      # Existing record
      if user.active?
        session[:sso]                   = { sso_provider: auth.provider, sso_uuid: auth.uid }
        session[:sso][:email]           = auth.info.email if auth.info && !auth.info.email.blank?
        session[:sso][:easy_avatar_url] = auth.info.image if auth.info && !auth.info.image.blank?

        successful_authentication(user)
      else
        handle_inactive_user(user)
      end
    end
  end

  def failure
    flash[:warning] = params[:message]

    redirect_back_or_default home_url
  end

end
