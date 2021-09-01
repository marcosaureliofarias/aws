module EasyPatch
  module AuthSourcePatch

    def self.included(base)
      base.class_eval do
        serialize :easy_options, EasyExtensions::UltimateHashSerializer

        safe_attributes 'easy_options'

        def self.disabled_sti_class
          EasyDisabledAuthSource
        end

        def editable?
          true
        end

        def to_s
          name
        end
      end
    end
  end

  module AuthSourceLdapPatch

    def self.included(base)
      base.class_eval do

        after_save :invalidate_counter_cache
        after_destroy :invalidate_counter_cache

        def available_attributes
          with_timeout do
            ldap_con = initialize_ldap_con(self.account, self.account_password)
            result   = ldap_con.search(:base => self.base_dn)
            return [] unless result
            result.map(&:attribute_names).flatten.uniq.sort
          end
        rescue *AuthSourceLdap::NETWORK_EXCEPTIONS,
          AuthSourceTimeoutException
          []
        end

        def available_users
          with_timeout do
            return [] unless searchable?
            ldap_con = initialize_ldap_con(self.account, self.account_password)
            result   = ldap_con.search(:base => self.base_dn, :filter => base_filter, :attributes => ['dn', self.attr_login, self.attr_firstname, self.attr_lastname, self.attr_mail])
            return [] unless result
            result
          end
        rescue *AuthSourceLdap::NETWORK_EXCEPTIONS,
          AuthSourceTimeoutException
          []
        end

        def invalidate_counter_cache
          Rails.cache.delete("auth_source_available_users_#{id}")
        end

        def available_users_count
          Rails.cache.fetch("auth_source_available_users_#{id}", :expires_in => 1.day) do
            begin
              available_users.count
            rescue StandardError
              0
            end
          end
        end

        def authenticate_without_password(login)
          return nil if login.blank?

          with_timeout do
            attrs = get_user_dn(login, nil)
            if attrs && attrs[:dn]
              logger.debug "Authentication successful for '#{login}'" if logger && logger.debug?
              return attrs.except(:dn)
            end
          end
        rescue *AuthSourceLdap::NETWORK_EXCEPTIONS,
          AuthSourceTimeoutException => e
          raise ::AuthSourceException.new(e.message)
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_patch_to_be_first 'AuthSource', 'EasyPatch::AuthSourcePatch'
EasyExtensions::PatchManager.register_model_patch 'AuthSourceLdap', 'EasyPatch::AuthSourceLdapPatch'
