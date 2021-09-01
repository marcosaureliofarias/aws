class EasyOauth2ClientApplication < EasyOauth2Application

  has_many :easy_oauth2_tokens, as: :entity, dependent: :destroy

  store_accessor :settings, :authorize_url, :token_url, :user_info_url, :onthefly_creation, :login_button

  safe_attributes 'app_id', 'app_secret', 'authorize_url', 'token_url', 'user_info_url', 'onthefly_creation', 'login_button'

  after_initialize :set_defaults

  validates :app_id, :app_secret, presence: true

  def oauth2_token
    fresh_oauth2_token
  end

  def access_token
    @access_token ||= easy_oauth2_tokens.detect { |t| t.key == 'access_token' }
  end

  def refresh_token
    @refresh_token ||= easy_oauth2_tokens.detect { |t| t.key == 'refresh_token' }
  end

  def authorized?
    access_token.present? && refresh_token.present?
  end

  def oauth2_login_path
    oauth2_path
  end

  def oauth2_authorization_path
    oauth2_path('authorization')
  end

  def login_button?
    self.login_button == '1'
  end

  def onthefly_creation?
    self.onthefly_creation == '1'
  end

  def user_identifier_attribute
    'mail'
  end

  private

  def oauth2_path(action = nil)
    p = "/auth/easy_oauth2_applications?guid=#{guid}"
    p << "&oauth2_action=#{action}" if action
    p
  end

  def oauth_client
    @oauth_client ||= ::OAuth2::Client.new(app_id, app_secret, site: app_url)
  end

  def fresh_oauth2_token
    new_token = old_token = create_oauth2_token

    if old_token && old_token.expires? && old_token.expired?
      begin
        new_token   = old_token.refresh!
        valid_until = Time.at(new_token.expires_at)

        access_token.update!(value: new_token.token, valid_until: valid_until)
        refresh_token.update!(value: new_token.refresh_token, valid_until: valid_until)
      rescue ::OAuth2::Error
        new_token = nil
      end
    end

    new_token
  end

  def create_oauth2_token
    return nil unless access_token && refresh_token

    begin
      ::OAuth2::AccessToken.new(
          oauth_client, access_token.value,
          { refresh_token: refresh_token.value,
            expires_at:    access_token.valid_until })
    rescue ::OAuth2::Error
      return nil
    end
  end

  def set_defaults
    return if persisted?

    self.authorize_url ||= '/oauth/authorize'
    self.token_url     ||= '/oauth/token'
    self.user_info_url ||= '/oauth/user'
  end

end
