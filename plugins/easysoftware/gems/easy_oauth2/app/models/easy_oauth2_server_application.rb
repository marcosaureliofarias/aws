class EasyOauth2ServerApplication < EasyOauth2Application

  before_validation :generate_secrets, on: [:create]

  def can_authorize?(user)
    true
  end

  private

  def generate_secrets
    self.app_id     = SecureRandom.hex(16)
    self.app_secret = SecureRandom.hex(16)
  end

end
