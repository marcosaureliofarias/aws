# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module EasySso
  module SamlClient
     class Hooks < ::Redmine::Hook::ViewListener
       #render_on :view_account_login_bottom, partial: 'account/easy_sso_saml_client/view_account_login_bottom'
     end
  end
end