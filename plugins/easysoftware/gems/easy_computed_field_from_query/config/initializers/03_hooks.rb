# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module EasyComputedFieldFromQuery
   class Hooks < ::Redmine::Hook::ViewListener
     render_on :view_easy_contacts_sidebar_buttons, partial: 'easy_contacts/sidebar_recalculate_button'
   end
end