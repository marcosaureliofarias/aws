class EasyOauthController < ApplicationController

  before_action :require_login, only: [:authorize]
  before_action :find_easy_oauth_client, only: [:authorize]
  skip_before_action :check_if_login_required, only: [:token]
  skip_before_action :verify_authenticity_token, only: [:token]

  accept_api_auth :user

  def authorize
    EasyOauthAccessGrant.prune!

    access_grant    = User.current.easy_oauth_access_grants.create(easy_oauth_client: @easy_oauth_client, state: params[:state])
    @authorize_link = access_grant.redirect_uri_for(params[:redirect_uri], params[:state])

    render layout: false
  end

  def token
    easy_oauth_client = EasyOauthClient.authenticate(params[:client_id], params[:client_secret])

    if easy_oauth_client.nil?
      render json: { error: 'Could not find application' }
      return
    end

    access_grant = EasyOauthAccessGrant.authenticate(params[:code], easy_oauth_client.id)
    if access_grant.nil?
      render json: { error: 'Could not authenticate access code' }
      return
    end

    access_grant.start_expiry_period!

    render json: { access_token: access_grant.access_token, refresh_token: access_grant.refresh_token, expires_in: Time.now + 30.minutes }
  end

  def user
    hash = {
        provider: 'sso',
        id:       User.current.easy_digest_token,
        info:     {
            id:         User.current.id,
            email:      User.current.mail,
            first_name: User.current.firstname,
            last_name:  User.current.lastname,
            name:       User.current.name,
            username:   User.current.login,
            status:     User.current.status,
            image:      avatar_url(User.current)
        },
        extra:    {},
        groups:   User.current.groups.map(&:as_json)
    }

    render json: hash.to_json
  end

  private

  def find_easy_oauth_client
    @easy_oauth_client = EasyOauthClient.find_by(app_id: params[:client_id])

    render_404 unless @easy_oauth_client
  end

end
