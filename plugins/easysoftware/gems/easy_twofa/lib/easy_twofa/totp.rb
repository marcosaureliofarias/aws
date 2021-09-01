require 'rotp'

module EasyTwofa
  ##
  # EasyTwofa::Totp
  #
  # Time-based One-time Password algorithm
  # The Time-based One-Time Password algorithm (TOTP) is an algorithm
  # that computes a one-time password from a shared secret key and the
  # current time. It has been adopted as Internet Engineering Task Force
  # standard RFC 6238, is the cornerstone of Initiative For Open Authentication
  # (OATH), and is used in a number of two-factor authentication systems.
  #
  # https://tools.ietf.org/html/rfc6238
  #
  class Totp < Auth

    DRIFT = 30

    def self.scheme_key
      :totp
    end

    def require_user_setup?
      true
    end

    def provisioning_uri
      totp = ROTP::TOTP.new(user_scheme.totp_key, issuer: Setting.app_title)
      totp.provisioning_uri(@user.mail)
    end

    def before_setup_user_scheme
      user_scheme.totp_key = ROTP::Base32.random
      user_scheme.totp_last_used_at = nil
    end

    def verify!(verify_code, **options)
      if !verify_check(verify_code, **options)
        return false
      end

      verify_code = verify_code.to_s.gsub(/\s/, '')

      totp = ROTP::TOTP.new(user_scheme.totp_key, issuer: Setting.app_title)

      verified_at = totp.verify(verify_code, drift_ahead: DRIFT,
                                             after: user_scheme.totp_last_used_at)

      if verified_at
        user_scheme.totp_last_used_at = verified_at
        user_scheme.save
        true
      else
        false
      end
    end

    def totp_key(formatted: false)
      key = user_scheme.totp_key
      if formatted
        key = key.scan(/.{4}/).join(' ')
      end
      key
    end

  end
end

EasyTwofa::Totp.register!
