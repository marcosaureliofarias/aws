if Redmine::Plugin.installed?(:easy_extensions)
  Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
    map.easy_category :easy_oauth2 do |pmap|
      pmap.rys_feature('easy_oauth2') do |fmap|

        # View on global

        fmap.permission(:view_easy_oauth2, {
            easy_oauth2_applications: [:index, :show]
        }, read: true, global: true)

        # Manage on global

        fmap.permission(:manage_easy_oauth2, {
            easy_oauth2_applications: [:new, :create, :edit, :update, :destroy, :authorization]
        }, require: :loggedin, global: true)

      end
    end

#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_oauth2 do |pmap|
#     map.rys_feature('easy_oauth2') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_oauth2, {
#         easy_oauth2: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_oauth2, {
#         easy_oauth2: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end

  end
end