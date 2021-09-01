module EasyExtensions
  class Sso

    class << self

      def enabled?
        EasySetting.value('enable_sso') && login_env_variable.present?
      end

      def login_env_variable
        EasySetting.value('sso_login_env_variable')
      end

      def get_login_from(request)
        request.env[login_env_variable]
      end

      def get_user_login(request)
        full_login = get_login_from(request)
        full_login.split('@').first if full_login.present?
      end

      def get_sso_user(request)
        return nil unless enabled?

        login = get_user_login(request)

        return nil unless login

        user = User.find_by(login: login)

        return user if user

        create_user_from_ldap(login)
      end

      def get_ldap_attrs(login)
        AuthSourceLdap.where(onthefly_register: true).each do |source|
          begin
            Rails.logger.debug "Authenticating '#{login}' against '#{source.name}'" if Rails.logger && Rails.logger.debug?
            attrs = source.authenticate_without_password(login)
          rescue => e
            Rails.logger.error "Error during authentication: #{e.message}" if Rails.logger
            attrs = nil
          end
          return attrs if attrs
        end

        nil
      end

      def create_user_from_ldap(login)
        attrs = get_ldap_attrs(login)

        return nil if attrs.blank?

        user       = User.new(attrs)
        user.login = login
        user.random_password
        user.activate
        user
      end

    end

  end
end
