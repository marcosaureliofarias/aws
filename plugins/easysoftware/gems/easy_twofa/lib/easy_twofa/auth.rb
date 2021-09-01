module EasyTwofa
  class Auth

    attr_reader :user, :last_verification_status

    mattr_accessor :schemes
    self.schemes = {}.with_indifferent_access

    def self.enabled_schemes
      enabled_schemes = EasySetting.value(:easy_twofa_enabled_schemes)

      if enabled_schemes.empty? || (enabled_schemes.size == 1 && enabled_schemes.first.blank?)
        schemes
      else
        schemes.select {|k, _| enabled_schemes.include?(k.to_s) }
      end
    end

    def self.register!
      schemes[scheme_key.to_s] = self
    end

    def self.for_user(user, scheme_key=nil)
      if scheme_key.blank?
        user_scheme = EasyTwofaUserScheme.find_by(user_id: user.id)
        scheme_key = user_scheme&.scheme_key
      end

      scheme_key = scheme_key.to_s
      enabled_schemes[scheme_key]&.new(user)
    end

    def self.scheme_key
      raise NotImplementedError
    end

    def self.setting_partial_path
    end

    def initialize(user)
      @user = user
    end

    def scheme_key
      self.class.scheme_key
    end

    def setup_partial_path
      "easy_twofa/#{scheme_key}/setup"
    end

    def verify_partial_path
      "easy_twofa/#{scheme_key}/verify"
    end

    def require_user_setup?
      false
    end

    def enable_resending?
      false
    end

    def setup_user_scheme!
      before_setup_user_scheme
      user_scheme.scheme_key = scheme_key
      user_scheme.save!
    end

    # This should be override in subclasses
    def before_setup_user_scheme
    end

    def disable!
      EasyTwofaUserScheme.where(user_id: @user.id).destroy_all
    end

    def prepare_verification
      @last_verification_status = VerificationStatus.new
      true
    end

    def t_setup_title
      I18n.translate(:setup_title, scope: [:easy_twofa, :schemes, scheme_key])
    end

    def t_setup_info
      I18n.translate(:setup_info, scope: [:easy_twofa, :schemes, scheme_key])
    end

    def t_name
      I18n.translate(:name, scope: [:easy_twofa, :schemes, scheme_key])
    end

    def activated?
      user_scheme.activated?
    end

    def activate!
      user_scheme.update_column(:activated, true)
    end

    def user_scheme
      @user_scheme ||= EasyTwofaUserScheme.find_or_initialize_by(user_id: @user.id)
    end

    def verify!(verify_code, **options)
      raise NotImplementedError
    end

    def verify_check(verify_code, **options)
      user_scheme &&
        user_scheme.scheme_key.to_s == scheme_key.to_s &&
        (options[:ignore_activated] ? true : user_scheme.activated?)
    end

    def device_remembered?(request)
      user_scheme.remembers.not_expired.any? do |remember|
        remember.device_match?(request)
      end
    end

  end
end
