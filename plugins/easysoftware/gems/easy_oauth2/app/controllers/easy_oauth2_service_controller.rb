class EasyOauth2ServiceController < ::ApplicationController

  before_action :require_login, only: [:authorized, :user]
  skip_before_action :check_if_login_required, only: [:authorize, :access_token]
  skip_before_action :verify_authenticity_token, only: [:access_token]
  before_action :find_easy_oauth2_application, only: [:authorize, :authorized]

  accept_api_auth :user

  def authorize
    if User.current.logged?
      if (access_code = get_authorized_access_code) &&
         (access_grant = User.current.easy_oauth2_access_grants.where(easy_oauth2_application: @easy_oauth2_application, code: access_code).first)

       redirect_to access_grant.redirect_uri_for(URI.decode(params[:redirect_uri].to_s), URI.decode(params[:state].to_s))
      else
       render 'authorize', layout: false
      end
    else
      redirect_to sso_login_path(back_url: oauth2_authorize_path(client_id:     params[:client_id],
                                                              redirect_uri:  params[:redirect_uri],
                                                              response_type: params[:response_type],
                                                              state:         params[:state],
                                                              referrer:      request.referrer))
    end
  end

  def authorized
    if @easy_oauth2_application.can_authorize?(User.current)
      access_grant = User.current.easy_oauth2_access_grants.create(
          easy_oauth2_application: @easy_oauth2_application,
          state:                   params[:state],
          referrer:                params[:referrer])

      set_authorized_access_code(access_grant)

      redirect_to access_grant.redirect_uri_for(params[:redirect_uri], params[:state])
    else
      redirect_to oauth2_access_denied_path(client_id: @easy_oauth2_application.app_id)
    end
  end

  def access_denied
  end

  def access_token
    app = EasyOauth2ServerApplication.active.find_by(app_id: params[:client_id], app_secret: params[:client_secret])

    if app.nil?
      render_error(message: "Could not find application #{params[:client_id]}", status: 401) && return
    end

    if params[:grant_type] == 'refresh_token'
      access_grant = EasyOauth2AccessGrant.find_by(easy_oauth2_application_id: app.id, refresh_token: params[:refresh_token])
    elsif params[:grant_type] == 'authorization_code'
      access_grant = EasyOauth2AccessGrant.find_by(easy_oauth2_application_id: app.id, code: params[:code])
    else
      render_error(message: "Unknown grant_type: #{params[:grant_type]}", status: 401) && return
    end

    if access_grant.nil?
      render_error(message: 'Could not authenticate access code', status: 401) && return
    end

    access_grant.start_expiry_period!

    render json: { access_token:  access_grant.access_token,
                   refresh_token: access_grant.refresh_token,
                   expires_at:    access_grant.access_token_expires_at.to_i }
  end

  def user
    hash = {
        provider: 'easy_oauth2',
        uid:      User.current.id,
        id:       User.current.id,
        email:    User.current.mail,
        info:     {
            name:        User.current.name,
            email:       User.current.mail,
            nickname:    User.current.login,
            first_name:  User.current.firstname,
            last_name:   User.current.lastname,
            location:    '',
            description: User.current.name,
            image:       avatar_url(User.current),
            phone:       '',

            sso_uuid:    User.current.sso_uuid,
            username:    User.current.login,
            locale:      User.current.language,
        },
        extra:    {
            raw_info: User.current.as_json
        }
    }

    render json: hash
  end

  private

  def find_easy_oauth2_application
    @easy_oauth2_application = EasyOauth2ServerApplication.active.find_by(app_id: params[:client_id])
    render_404 if @easy_oauth2_application.nil?
  end

  def get_authorized_access_code
    aua = @easy_oauth2_application.easy_oauth2_application_user_authorizations.where(user: User.current).first
    aua && aua.code
  end

  def set_authorized_access_code(access_grant)
    @easy_oauth2_application.easy_oauth2_application_user_authorizations.create(
        user:    User.current,
        code:    access_grant.code,
        browser: request.env['HTTP_USER_AGENT'])
  end

end
