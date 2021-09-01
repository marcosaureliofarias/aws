# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module EasyTwofa
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_my_account, partial: 'my/easy_twofa/view_my_account'
    render_on :view_users_form, partial: 'my/easy_twofa/view_users_form'

    def view_settings_authentication_form(context={})
      if EasyTwofa.easy_extensions? && Rys::Feature.active?('easy_twofa')
        context[:hook_caller].render('easy_twofa/setting', context)
      else
        # Redmine is using new page
      end
    end

  end
end
