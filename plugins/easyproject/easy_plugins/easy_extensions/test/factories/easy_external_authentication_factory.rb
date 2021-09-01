FactoryGirl.define do

  factory(:easy_external_authentication) do
    user { nil }
    provider { 'google' }
    access_token { SecureRandom.hex }
    refresh_token { SecureRandom.hex }
    expires_in { 3600 }
    issued_at { Time.now }
  end

end
