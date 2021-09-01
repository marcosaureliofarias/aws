module Admin
  class EasyAdminController < ApplicationController
    accept_api_auth :version, :monitoring, :enabled_plugins

    def version
      respond_to do |format|
        format.html { render plain: "#{EasyExtensions.full_version} (Repository built: #{EasyExtensions.build_version})" }
        format.api
      end
    end

    def enabled_plugins
      render json: Redmine::Plugin.all(only_visible: true, without_disabled: true).map(&:name)
    end

    private

    def require_login
      false # no login required. Override Redmine setting
    end
  end
end
