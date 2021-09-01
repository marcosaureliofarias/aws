class EasyOauthClient < ActiveRecord::Base

  validates :app_id, uniqueness: true

  def self.authenticate(app_id, app_secret)
    where(app_id: app_id, app_secret: app_secret).first
  end

  def name
    original_name = super
    if original_name == 'internal'
      Setting.host_name.to_s
    else
      original_name
    end
  end

end
