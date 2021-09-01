class EasyOauth2AccessGrant < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :user
  belongs_to :easy_oauth2_application

  scope :valid_for, ->(token) do
    where(arel_table[:access_token].eq(token).and(
        arel_table[:access_token_expires_at].gteq(Time.now).or(arel_table[:access_token_expires_at].eq(nil))
    ))
  end

  before_create :generate_tokens

  def redirect_uri_for(redirect_uri, state)
    if redirect_uri =~ /\?/
      redirect_uri + "&code=#{code}&response_type=code&state=#{state}"
    elsif redirect_uri
      redirect_uri + "?code=#{code}&response_type=code&state=#{state}"
    else
      '/'
      # Rails.application.routes.url_helpers.root_path
    end
  end

  def start_expiry_period!
    self.update(
        access_token_expires_at: Time.now + 1.day,
        access_token:            SecureRandom.hex(16),
        refresh_token:           SecureRandom.hex(16)
    )
  end

  private

  def generate_tokens
    self.code          = SecureRandom.hex(16)
    self.access_token  = SecureRandom.hex(16)
    self.refresh_token = SecureRandom.hex(16)
  end

end
