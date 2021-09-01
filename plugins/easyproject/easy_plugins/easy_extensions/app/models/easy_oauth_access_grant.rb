class EasyOauthAccessGrant < ActiveRecord::Base

  belongs_to :user
  belongs_to :easy_oauth_client

  before_create :generate_tokens

  def self.prune!
    where(['created_at < ?', 3.days.ago]).delete_all
  end

  def self.authenticate(code, application_id)
    find_by(code: code, easy_oauth_client_id: application_id)
  end

  def generate_tokens
    self.code          = SecureRandom.hex(16)
    self.access_token  = user.api_key #SecureRandom.hex(16)
    self.refresh_token = SecureRandom.hex(16)
  end

  def redirect_uri_for(redirect_uri, state)
    if /\?/.match?(redirect_uri)
      redirect_uri + "&code=#{code}&response_type=code&state=#{state}"
    else
      redirect_uri + "?code=#{code}&response_type=code&state=#{state}"
    end
  end

  def start_expiry_period!
    self.update_attribute(:access_token_expires_at, Time.now + 30.minutes)
  end

end
