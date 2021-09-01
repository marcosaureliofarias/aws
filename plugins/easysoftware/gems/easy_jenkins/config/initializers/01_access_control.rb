Redmine::AccessControl.map do |map|

  # ---------------------------------------------------------------------------
  # Global level

  # View on global

  # map.permission(:view_easy_jenkins, {
  #   easy_jenkins: [:index, :show]
  # }, read: true, global: true)

  # # Manage on global

  # map.permission(:manage_easy_jenkins, {
  #   easy_jenkins: [:new, :create, :edit, :update, :destroy]
  # }, require: :loggedin, global: true)

  # ---------------------------------------------------------------------------
  # Project level

  map.project_module :easy_jenkins do |pmap|
    map.rys_feature('easy_jenkins.settings') do |fmap|
      # Edit settings on project

      fmap.permission(:manage_easy_jenkins_settings, {
        easy_jenkins_settings: [
          :create,
          :update,
          :autocomplete_issues,
          :autocomplete_jobs,
          :project_settings,
          :test_connection
        ]
      }, require: :loggedin)
    end

    map.rys_feature('easy_jenkins.pipelines') do |fmap|
      # Edit pipelines on project

      fmap.permission(:manage_easy_jenkins_pipelines, {
        easy_jenkins_pipelines: [
          :run,
          :history
        ]
      }, require: :loggedin)
    end
  end;

end