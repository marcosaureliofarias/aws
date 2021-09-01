class EasyLicenseManager

  class << self

    def stored_license_key
      EasySetting.value('license_key')
    end

    def apply_valid_key(key = nil)
      easy_license_key = get_valid_easy_license_key(key)

      return false if !easy_license_key.is_a?(::EasyLicenseKey)

      easy_license_key.apply_license_key

      EasyUtils::ShellUtils.restart_server

      return true
    end

    def get_valid_easy_license_key(key = nil)
      EasyLicenseKey.get_valid_easy_license_key(key || stored_license_key, Setting.host_name)
    end

    def has_license_limit?(license_key)
      method = "validate_#{license_key.to_s}".to_sym

      return send(method) if respond_to?(method)
    end

    def get_license_limit(license_key)
      method = "get_#{license_key.to_s}".to_sym

      return send(method) if respond_to?(method)
    end

    def get_internal_user_limit
      EasySetting.value('internal_user_limit').to_i
    end

    def get_internal_user_count
      User.active.easy_type_internal.where(type: 'User').count
    end

    def get_external_user_limit
      EasySetting.value('external_user_limit').to_i
    end

    def get_external_user_count
      User.active.easy_type_external.where(type: 'User').count
    end

    def get_active_project_limit
      EasySetting.value('active_project_limit').to_i
    end

    def get_active_project_count
      Project.non_templates.where(status: [Project::STATUS_ACTIVE, Project::STATUS_CLOSED]).count
    end

    def validate_internal_user_limit
      return true if !EasyUserType.table_exists?
      internal_limit = get_internal_user_limit
      (internal_limit == 0 || internal_limit > get_internal_user_count) ? true : false
    end

    def validate_external_user_limit
      return true if !EasyUserType.table_exists?
      external_limit = get_external_user_limit
      (external_limit == 0 || external_limit > get_external_user_count) ? true : false
    end

    def validate_active_project_limit
      active_project_limit = get_active_project_limit
      (active_project_limit == 0 || active_project_limit > get_active_project_count) ? true : false
    end

  end

end
