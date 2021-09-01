# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks

module SecurityUserLock
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_settings_authentication_form, partial: 'settings/lock_user_settings'
    render_on :view_account_easy_page_layout_service_box, partial: 'users/unlock_user'

    def easy_extensions_javascripts_hook(context={})
      context[:template].require_asset('security_user_lock/security_user_lock')
    end
  end
end
