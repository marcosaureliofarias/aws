# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module EasyActions
   class Hooks < ::Redmine::Hook::ViewListener

     render_on :view_easy_git_repositories_sidebar_buttons, partial: 'easy_actions/hooks/view_easy_git_repositories_sidebar_buttons'
     render_on :view_easy_git_repositories_bottom, partial: 'easy_actions/hooks/sequence_entity_detail'
     render_on :view_easy_git_code_requests_bottom, partial: 'easy_actions/hooks/view_easy_git_code_requests_bottom'

   end
end