Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
    map.easy_category :easy_integrations do |pmap|
      pmap.rys_feature('easy_integrations') do |fmap|

        # View on global

        fmap.permission(:view_easy_integrations, {
            easy_integrations: [:index]
        }, require: :admin, read: true, global: true)

        # Manage on global

        fmap.permission(:manage_easy_integrations, {
            easy_integrations: [:new, :create, :edit, :update, :destroy]
        }, require: :admin, global: true)

      end
    end

#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_integrations do |pmap|
#     map.rys_feature('easy_integrations') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_integrations, {
#         easy_integrations: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_integrations, {
#         easy_integrations: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
end if Redmine::Plugin.installed?(:easy_extensions)