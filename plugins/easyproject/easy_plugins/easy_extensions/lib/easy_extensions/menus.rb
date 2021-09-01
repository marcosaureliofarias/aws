Redmine::MenuManager.map :admin_menu do |menu|
  menu.delete :projects
  menu.delete :users
  menu.delete :groups
  menu.delete :roles
  menu.delete :trackers
  menu.delete :issue_statuses
  menu.delete :workflows
  menu.delete :custom_fields
  menu.delete :enumerations
  menu.delete :settings
  menu.delete :ldap_authentication
  menu.delete :plugins
  menu.delete :info

  menu.push :projects, { :controller => 'admin', :action => 'projects', :set_filter => 0 }, :caption => :label_project_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:projects) }, :html => { :class => 'icon icon-project' }
  menu.push :templates, :templates_path, :caption => :label_templates_plural, :if => Proc.new { Project.allowed_to_create_project_from_template? }, :after => :projects, :html => { :class => 'icon icon-templates' }
  menu.push :users, { :controller => 'users' }, :caption => :label_user_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:users) }, :html => { :class => 'icon icon-user' }
  menu.push :groups, { :controller => 'groups' }, :caption => :label_group_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:groups) }, :html => { :class => 'icon icon-group' }
  menu.push :easy_user_types, { :controller => 'easy_user_types' }, :caption => :label_easy_user_type_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_user_types) }, :html => { :class => 'icon icon-people' }
  menu.push :working_time, { :controller => 'easy_user_working_time_calendars', :action => 'index' }, :caption => :label_admin_easy_user_working_time_calendars, :html => { :class => 'icon icon-calendar' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:working_time) }, :after => :user_types
  menu.push :roles, { :controller => 'roles' }, :caption => :label_role_and_permissions, :if => Proc.new { User.current.easy_lesser_admin_for?(:roles) }, :html => { :class => 'icon icon-roles' }
  menu.push :trackers, { :controller => 'trackers' }, :caption => :label_tracker_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:trackers) }, :html => { :class => 'icon icon-tracker' }
  menu.push :issue_statuses, { :controller => 'issue_statuses' }, :caption => :label_issue_status_plural, :html => { :class => 'icon icon-issue-status' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:issue_statuses) }
  menu.push :workflows, { :controller => 'workflows', :action => 'edit' }, :caption => :label_workflow, :if => Proc.new { User.current.easy_lesser_admin_for?(:workflows) }, :html => { :class => 'icon icon-workflow' }
  menu.push :easy_issue_timer_settings, { :controller => 'easy_issue_timers', :action => 'settings' }, :caption => :label_easy_issue_timer_settings, :html => { :class => 'icon icon-timer' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_issue_timer_settings) }
  menu.push :custom_fields, { :controller => 'custom_fields' }, :caption => :label_custom_field_plural, :html => { :class => 'icon icon-cf' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:custom_fields) }
  menu.push :enumerations, { :controller => 'enumerations' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:enumerations) }, :html => { :class => 'icon icon-list' }
  menu.push :easy_query_settings, { :controller => 'easy_query_settings', :action => 'index' }, :caption => :label_easy_query_settings, :html => { :class => 'icon icon-filter' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_query_settings) }, :after => :settings
  menu.push :ldap_authentication, { :controller => 'auth_sources', :action => 'index' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:ldap_authentication) }, :html => { :class => 'icon icon-server' }
  menu.push :easy_pages_administration, { :controller => 'easy_pages', :action => 'index' }, :caption => :label_easy_pages_project_administration, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_pages_administration) }, :html => { :class => 'icon icon-page' }
  menu.push :easy_rake_tasks, { :controller => 'easy_rake_tasks', :action => 'index' }, :caption => :'easy_rake_tasks.views.button_index', :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_rake_tasks) }, :html => { :class => 'icon icon-stack' }
  menu.push :easy_xml_data_import, { :controller => 'easy_xml_data', :action => 'import_settings' }, :caption => :label_xml_data_import, :if => Proc.new { |p| User.current.easy_lesser_admin_for?(:easy_xml_data_import) }, :html => { :class => 'icon icon-import' }
  menu.push :settings, { :controller => 'settings' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:settings) }, :html => { :class => 'icon icon-settings' }
  menu.push :easy_pdf_themes, { :controller => 'easy_pdf_themes', :action => 'index' }, :html => { :class => 'icon icon-watcher' }, :caption => :label_easy_gantt_theme_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_pdf_themes) }
  menu.push :easy_currency, { :controller => 'easy_currencies', :action => 'index' }, :if => Proc.new { User.current.admin? }, :html => { :class => 'icon icon-money' }, :before => :settings
  menu.push :easy_query_management, { :controller => 'easy_query_management', :action => 'edit', type: 'EasyIssueQuery' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_query_settings) }, :html => { :class => 'icon icon-filter' }, :before => :easy_query_settings
  menu.push :plugins, { :controller => 'admin', :action => 'manage_plugins' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:plugins) }, :html => { :class => 'icon icon-package' }, :last => true
end

Redmine::MenuManager.map :admin_dashboard do |menu|
  menu.push :projects, { :controller => 'admin', :action => 'projects', :set_filter => 0 }, :caption => :label_project_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:projects) }, :html => { :menu_category => 'projects', :class => 'icon icon-project' }
  menu.push :templates, :templates_path, :caption => :label_templates_plural, :if => Proc.new { Project.allowed_to_create_project_from_template? }, :after => :projects, :html => { :menu_category => 'projects', :class => 'icon icon-templates' }
  menu.push :trackers, { :controller => 'trackers' }, :caption => :label_tracker_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:trackers) }, :html => { :menu_category => 'issues', :class => 'icon icon-tracker' }
  menu.push :issue_statuses, { :controller => 'issue_statuses' }, :caption => :label_issue_status_plural, :html => { :menu_category => 'issues', :class => 'icon icon-issue-status' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:issue_statuses) }
  menu.push :workflows, { :controller => 'workflows', :action => 'edit' }, :caption => :label_workflow, :if => Proc.new { User.current.easy_lesser_admin_for?(:workflows) }, :html => { :menu_category => 'issues', :class => 'icon icon-workflow' }
  menu.push :users, { :controller => 'users' }, :caption => :label_user_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:users) }, :html => { :menu_category => 'users', :class => 'icon icon-user' }
  menu.push :groups, { :controller => 'groups' }, :caption => :label_group_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:groups) }, :html => { :menu_category => 'users', :class => 'icon icon-group' }
  menu.push :easy_user_types, { :controller => 'easy_user_types' }, :caption => :label_easy_user_type_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_user_types) }, :html => { :menu_category => 'users', :class => 'icon icon-people' }

  menu.push :easy_standardized_imports, :easy_imports_path,
            caption: :'easy_imports.label_standardized_imports',
            html:    { menu_category: 'imports', class: 'icon icon-brick-2', link_options: { remote: true } },
            if:      proc { User.current.admin? },
            after:   :users

  menu.push :easy_xml_imports, :easy_xml_data_import_settings_path,
            caption: :label_xml_data_import_dashboards_and_project_templates,
            html:    { menu_category: 'imports', class: 'icon icon-import' },
            if:      proc { User.current.admin? }

  menu.push :easy_entity_imports, :easy_entity_imports_path,
            caption: :label_custom_imports,
            html:    { menu_category: 'imports', class: 'icon icon-warning' },
            if:      proc { User.current.admin? }

  menu.push :ldap_authentication, :auth_sources_path,
            html:  { menu_category: 'security', class: 'icon icon-server' },
            if:    proc { User.current.easy_lesser_admin_for?(:ldap_authentication) },
            after: :easy_standardized_imports

  menu.push :roles, { :controller => 'roles' }, :caption => :label_role_and_permissions, :if => Proc.new { User.current.easy_lesser_admin_for?(:roles) }, :html => { :menu_category => 'security', :class => 'icon icon-roles' }, :after => :groups
  menu.push :plugins, { :controller => 'admin', :action => 'manage_plugins' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:plugins) }, :last => true, :html => { :menu_category => 'extensions', :class => 'icon icon-package' }
  menu.push :working_time, { :controller => 'easy_user_working_time_calendars', :action => 'index' }, :caption => :label_admin_easy_user_working_time_calendars, :html => { :menu_category => 'settings', :class => 'icon icon-calendar' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:working_time) }, :after => :groups
  menu.push :custom_fields, { :controller => 'custom_fields' }, :caption => :label_custom_field_plural, :html => { :menu_category => 'settings', :class => 'icon icon-cf' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:custom_fields) }
  menu.push :enumerations, { :controller => 'enumerations' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:enumerations) }, :html => { :menu_category => 'settings', :class => 'icon icon-list' }
  menu.push :easy_query_settings, { :controller => 'easy_query_settings', :action => 'index' }, :caption => :label_easy_query_settings, :html => { :menu_category => 'settings', :class => 'icon icon-filter' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_query_settings) }, :after => :settings
  menu.push :easy_pages_administration, { :controller => 'easy_pages', :action => 'index' }, :caption => :label_easy_pages_project_administration, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_pages_administration) }, :html => { :menu_category => 'settings', :class => 'icon icon-page' }
  menu.push :settings, { :controller => 'settings' }, :if => Proc.new { User.current.easy_lesser_admin_for?(:settings) }, :html => { :menu_category => 'settings', :class => 'icon icon-settings' }
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.delete :home
  menu.delete :my_page
  menu.delete :projects
  menu.delete :administration
  menu.delete :help

  menu.push(:personal_statement, { :controller => 'easy_time_entries', :action => 'index', :only_me => true, :project_id => nil }, {
      :caption => :label_personal_statement,
      :if      => Proc.new { User.current.allowed_to_globally?(:view_personal_statement, {}) && EasySetting.value('show_personal_statement') },
      :html    => { :class => 'icon icon-user' }
  })
  menu.push(:personal_statement_log_time, :new_easy_time_entry_path, {
      :parent  => :personal_statement,
      :if      => Proc.new { User.current.allowed_to_globally?(:log_time, {}) && EasySetting.value('show_bulk_time_entry') },
      :caption => :button_log_time
  })
  menu.push(:easy_resource_booking_modul, :easy_resource_availabilities_path,
            :caption => :label_easy_resource_booking_module_top_menu,
            :if      => Proc.new { User.current.allowed_to_globally?(:view_easy_resource_booking_module, {}) && EasySetting.value(:show_easy_resource_booking) },
            :html    => { :class => 'icon icon-bookmark' }
  )

  menu.push(:users, :users_path, {
      :caption => :label_user_plural,
      :if      => Proc.new { User.current.easy_lesser_admin_for?(:users) },
      :html    => { :class => 'icon icon-user' }
  })
  menu.push(:users_new, :new_user_path, {
      :caption => :label_user_new,
      :if      => Proc.new { User.current.easy_lesser_admin_for?(:users) && (EasyLicenseManager.has_license_limit?(:internal_user_limit) || EasyLicenseManager.has_license_limit?(:external_user_limit)) },
      :parent  => :users
  })
  menu.push(:users_find_by_user, { :controller => 'users', :action => 'find_by_user' }, {
      :parent  => :users,
      :caption => :label_users_find_by_user,
      :html    => { :remote => true },
      :if      => Proc.new { User.current.easy_lesser_admin_for?(:users) }
  })

  menu.push :others, '#', {
      :caption => :label_others,
      :html    => { :class => 'icon icon-folder' },
      :before  => :administration
  }
  menu.push(:documents, :documents_path, {
      :parent  => :others,
      :caption => :label_document_global,
      :if      => Proc.new { User.current.allowed_to_globally?(:view_documents, {}) },
      # :before => :administration,
      :html => { :class => 'icon icon-copy' }
  })
  menu.push(:easy_versions, :easy_versions_path, {
      :parent  => :others,
      :caption => :label_easy_versions_top_menu,
      :if      => Proc.new { User.current.allowed_to_globally?(:manage_global_versions, {}) },
      :html    => { :class => 'icon icon-list' }
  })

  menu.push :administration, :admin_path, {
      :if   => Proc.new { User.current.admin? || User.current.easy_lesser_admin? },
      :html => { :service => true, :class => 'icon icon-settings' }
  }
  menu.push :login, :signin_path, {
      :if    => Proc.new { !User.current.logged? },
      :after => :administration,
      :html  => { :service => true, :class => 'icon icon-move' }
  }
  menu.push :register, :register_path, {
      :if    => Proc.new { !User.current.logged? && Setting.self_registration? },
      :after => :login,
      :html  => { :service => true, :class => 'icon icon-server-authentication' }
  }
  menu.push :my_account, { :controller => 'users', :action => 'show' }, {
      :param => Proc.new { |p| { :id => User.current } },
      :after => :administration,
      :html  => { :service => true, :class => 'icon icon-user' }
  }
  menu.push :logout, :signout_path, {
      :if    => Proc.new { User.current.logged? },
      :html  => { :method => 'post', :service => true, :class => 'icon icon-power' },
      :after => :my_account
  }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.delete :login
  menu.delete :register
  menu.delete :my_account
  menu.delete :logout

  menu.push :administration, :admin_path, {
      :if   => Proc.new { (User.current.admin? || User.current.easy_lesser_admin?) && User.current.easy_user_type_for?(:administration) },
      :html => { :service => true, :class => 'icon icon-settings' }
  }
  menu.push :my_account, { :controller => 'users', :action => 'show' }, {
      :param => Proc.new { |p| { :id => User.current } },
      :if    => Proc.new { User.current.easy_user_type_for?(:user_profile) },
      :after => :administration,
      :html  => { :service => true, :class => 'icon icon-user' }
  }
  menu.push :logout, :signout_path, {
      :if    => Proc.new { User.current.logged? && User.current.easy_user_type_for?(:sign_out) },
      :html  => { :method => 'post', :service => true, :class => 'icon icon-power' },
      :after => :my_account
  }
end

Redmine::MenuManager.map :easy_quick_top_menu do |menu|
  menu.push :my_page, { controller: 'my', action: 'page', id: nil },
            if:      proc { !User.current.in_mobile_view? && User.current.easy_user_type_for?(:home_icon) },
            caption: "<i class='icon-home'></i>".html_safe,
            html:    { :title => EasyExtensions::MenuManagerProc.new { I18n.t(:label_home) } }
  menu.push :projects, { controller: 'projects', action: 'index', set_filter: 0, id: nil },
            caption: :label_project_plural,
            if:      proc { (Setting.login_required? ? User.current.logged? : true) && User.current.easy_user_type_for?(:projects) }
  menu.push :new_project, :new_project_path, {
      parent:  :projects,
      caption: :label_project_new,
      html:    { class: 'icon icon-add' },
      if:      proc { EasyLicenseManager.has_license_limit?(:active_project_limit) && (User.current.allowed_to_globally?(:add_project) || User.current.allowed_to_globally?(:add_subprojects)) }
  }
  menu.push :new_project_from_template, :templates_path, {
      parent: :projects,
      html:   { class: 'icon icon-add' },
      if:     proc { EasyLicenseManager.has_license_limit?(:active_project_limit) && Project.allowed_to_create_project_from_template? },
  }
  menu.push(:projects_find_by_easy_query, { controller: 'easy_queries', action: 'find_by_easy_query', :type => 'EasyProjectQuery', :title => :label_projects_find_by_easy_query }, {
      :parent  => :projects,
      :caption => :label_projects_find_by_easy_query,
      :html    => { :remote => true, :class => 'icon icon-filter' },
      :if      => Proc.new { Setting.login_required? ? User.current.logged? : true }
  })

  menu.push(:projects_favorited, { :controller => 'projects', :action => 'index', :set_filter => 1, :favorited => 1 }, {
      :parent  => :projects,
      :caption => :button_show_favorite_projects,
      :html    => { :class => 'icon icon-fav' },
      :if      => Proc.new { Setting.login_required? ? User.current.logged? : true }
  })
  menu.push(:project_spent_time, { :controller => 'easy_time_entries', :action => 'index', :set_filter => '0' }, {
      :parent  => :projects,
      :param   => :project_id,
      :caption => :label_spent_time,
      :html    => { :class => 'icon icon-time' },
      :if      => Proc.new { User.current.allowed_to_globally_view_all_time_entries? }
  })

  menu.push :issues, { :controller => 'issues', :action => 'index', :set_filter => 0, :project_id => nil, :id => nil },
            :caption => :label_issue_plural,
            :if      => Proc.new { (Setting.login_required? ? User.current.logged? : true) && User.current.allowed_to?(:view_issues, nil, :global => true) && User.current.easy_user_type_for?(:issues) }
  menu.push(:issues_new, :new_issue_path, {
      :parent  => :issues,
      :caption => :label_issue_new,
      :html    => { :class => 'icon icon-add' },
      :if      => Proc.new { User.current.allowed_to?(:add_issues, nil, :global => true) }
  })
  menu.push(:issues_my, { :controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => 'me', :status_id => 'o', :project_id => nil }, {
      :parent  => :issues,
      :caption => :label_issues_assigned_to_me,
      :html    => { :class => 'icon icon-issue' },
      :if      => Proc.new { User.current.logged? && User.current.allowed_to?(:view_issues, nil, :global => true) }
  })
  menu.push(:issues_find_by_user, { :controller => 'easy_issues', :action => 'find_by_user' }, {
      :parent  => :issues,
      :caption => :sidebar_all_users_queries,
      :html    => { :remote => true, :class => 'icon icon-user' },
      :if      => Proc.new { (Setting.login_required? ? User.current.logged? : true) && User.current.allowed_to?(:view_issues, nil, :global => true) }
  })
  menu.push(:issues_find_by_easy_query, { controller: 'easy_queries', action: 'find_by_easy_query', :type => 'EasyIssueQuery', :title => :label_issues_find_by_easy_query }, {
      :parent  => :issues,
      :caption => :label_issues_find_by_easy_query,
      :html    => { :remote => true, :class => 'icon icon-filter' },
      :if      => Proc.new { (Setting.login_required? ? User.current.logged? : true) && User.current.allowed_to?(:view_issues, nil, :global => true) }
  })
  menu.push(:issues_favorited, { :controller => 'issues', :action => 'index', :set_filter => 1, :favorited => 1 }, {
      :parent  => :issues,
      :caption => :button_show_favorite_issues,
      :html    => { :class => 'icon icon-fav' },
      :if      => Proc.new { (Setting.login_required? ? User.current.logged? : true) && User.current.allowed_to?(:view_issues, nil, :global => true) }
  })
  menu.push(:issues_calendar, { :controller => 'calendars', :action => 'show' }, {
      :parent  => :issues,
      :caption => :label_calendar,
      :html    => { :class => 'icon icon-calendar' },
      :if      => Proc.new { User.current.allowed_to?(:view_calendar, nil, :global => true) }
  })
  menu.push(:issues_overall_activity, { :controller => 'activities', :action => 'index' }, {
      :parent  => :issues,
      :caption => :label_overall_activity,
      :html    => { :class => 'icon icon-time' },
      :if      => Proc.new { User.current.allowed_to?(:view_project_activity, nil, :global => true) && User.current.internal_client? }
  })
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.delete :overview
  menu.delete :activity
  menu.delete :roadmap
  menu.delete :issues
  menu.delete :new_issue
  menu.delete :gantt
  menu.delete :calendar
  menu.delete :news
  menu.delete :documents
  menu.delete :wiki
  menu.delete :boards
  menu.delete :time_entries
  menu.delete :files
  menu.delete :repository
  menu.delete :settings
  menu.delete :new_object

  menu.push :overview, { :controller => 'projects', :action => 'show', :jump => 'overview' }, :first => true
  menu.push :issues, { :controller => 'issues', :action => 'index', :set_filter => '0' }, :param => :project_id, :caption => :label_issue_plural, :if => Proc.new { |p| User.current.allowed_to?(:view_issues, p) }
  menu.push :time_entries, { :controller => 'easy_time_entries', :action => 'index' }, :param => :project_id, :caption => :label_spent_time, :if => Proc.new { |p| User.current.allowed_to?(:view_time_entries, p) }, :after => :new_issue
  menu.push :news, { :controller => 'news', :action => 'index' }, :param => :project_id, :caption => :label_news_plural, :after => :time_entries
  menu.push :documents, { :controller => 'documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural, :if => Proc.new { |p| User.current.allowed_to?(:view_documents, p) }, :after => :news
  menu.push :roadmap, { :controller => 'versions', :action => 'index' }, :param => :project_id, :caption => :label_roadmap, :if => Proc.new { |p| p.shared_versions.any? }, :after => :documents
  menu.push :calendar, { :controller => 'calendars', :action => 'show' }, :param => :project_id, :caption => :label_calendar, :if => Proc.new { |p| User.current.allowed_to?(:view_calendar, p) && !User.current.in_mobile_view? }
  menu.push :wiki, { :controller => 'wiki', :action => 'show', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.wiki && !p.wiki.new_record? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('wiki') }
  menu.push :boards, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.boards.any? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('boards') }, :caption => :label_board_plural
  menu.push :files, { :controller => 'files', :action => 'index' }, :caption => :label_file_plural, :param => :project_id, :if => Proc.new { |p| !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('files') }
  menu.push :repository, { :controller => 'repositories', :action => 'show', :repository_id => nil, :path => nil, :rev => nil }, :if => Proc.new { |p| p.repository && !p.repository.new_record? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('repository') }
  menu.push :settings, { :controller => 'projects', :action => 'settings' }, :caption => :label_settings, :if => Proc.new { |p| p.editable? }, :last => true
end

Redmine::MenuManager.map :projects_easy_page_layout_service_box do |menu|
  menu.push :new_project, :new_project_path, {
      param:   :project_id,
      caption: :label_project_new,
      html:    { class: 'button-positive icon icon-add', render_partial_path: 'projects/new_project_button' },
      if:      proc { User.current.allowed_to_globally?(:add_project) || User.current.allowed_to_globally?(:add_subprojects) },
      first:   true
  }
  menu.push :new_project_from_template, :templates_path, {
      html:  { class: 'button-positive icon icon-add' },
      if:    proc { Project.allowed_to_create_project_from_template? && EasyLicenseManager.has_license_limit?(:active_project_limit) },
      after: :new_project
  }
  menu.push :time_entries, { :controller => 'easy_time_entries', :action => 'index', :set_filter => '0' }, :caption => :label_spent_time, :html => { :class => 'button icon icon-time' }, :if => Proc.new { User.current.allowed_to_globally_view_all_time_entries? }
end

Redmine::MenuManager.map :admin_projects_easy_page_layout_service_box do |menu|
  menu.push :new_project, :new_project_path, {
      param:   :project_id,
      caption: :label_project_new,
      html:    { class: 'button-positive icon icon-add', render_partial_path: 'projects/new_project_button' },
      if:      proc { User.current.allowed_to_globally?(:add_project) || User.current.allowed_to_globally?(:add_subprojects) },
      first:   true
  }
  menu.push :new_project_from_template, :templates_path, {
      html:  { class: 'button-positive icon icon-add' },
      if:    proc { Project.allowed_to_create_project_from_template? && EasyLicenseManager.has_license_limit?(:active_project_limit) },
      after: :new_project
  }


  menu.push :project_mass_copy, { :controller => 'project_mass_copy', :action => 'select_source_project' }, :caption => :button_project_mass_copy, :html => { :class => 'button icon icon-copy' }, :if => Proc.new { User.current.admin? }
end


Redmine::MenuManager.map :easy_servicebar_items do |menu|
  menu.push(:easy_issue_timers_list_trigger, :get_current_user_timers_path, :html => {
      :class  => 'icon-timer reverse',
      :id     => 'easy_issue_timers_list_trigger',
      :title  => EasyExtensions::MenuManagerProc.new { I18n.t(:label_easy_issue_timer) },
      :style  => 'visibility:hidden',
      :remote => true
  },
            :caption                                                              => '',
            :last                                                                 => true,
            :if                                                                   => Proc.new { |project| User.current.logged? }
  )
  menu.push(:easy_activity_feed_toolbar, { :controller => 'easy_activities', :action => 'show_toolbar' },
            :html    => {
                :class  => 'icon-stack',
                :id     => 'easy_activity_feed_trigger',
                :title  => EasyExtensions::MenuManagerProc.new { I18n.t(:label_easy_activity_feed) },
                :remote => true
            },
            :caption => '',
            :param   => :project_id,
            :if      => Proc.new { User.current.allowed_to_globally?(:view_project_activity, {}) }
  )
end


Redmine::MenuManager.map :user_profile do |menu|
  menu.push :issues, :user_profile_menu_item_assigned_issues,
            :caption => EasyExtensions::MenuManagerProc.new { I18n.t(:label_issue_plural).html_safe + '&nbsp;<i class=\'icon-arrow down\'></i>'.html_safe },
            :html    => { :class => 'icon icon-issue' },
            :if      => Proc.new { User.current.internal_client? }
  menu.push :issues_new_issue, :user_profile_menu_item_new_issue,
            :parent  => :issues,
            :caption => :label_issue_new,
            :html    => { :class => 'icon icon-add' },
            :if      => Proc.new { !User.current.easy_user_type_for?(:hide_new_issue_button) }
  menu.push :issues_assigned_issues, :user_profile_menu_item_assigned_issues,
            :parent  => :issues,
            :caption => :label_issues_assigned_to,
            :html    => { :class => 'icon icon-filter' },
            :if      => Proc.new { User.current.internal_client? }
  menu.push :issues_assigned_issues_after_due_date, :user_profile_menu_item_assigned_issues_after_due_date,
            :parent  => :issues,
            :caption => :label_issues_after_due_date,
            :html    => { :class => 'icon icon-filter' },
            :if      => Proc.new { User.current.internal_client? }
  menu.push :issues_assigned_issues_not_updated, :user_profile_menu_item_assigned_issues_not_updated,
            :parent  => :issues,
            :caption => :label_issues_not_updated,
            :html    => { :class => 'icon icon-filter' },
            :if      => Proc.new { User.current.internal_client? }


  menu.push :time_entries, :user_profile_menu_item_time_entries,
            :caption => :label_spent_time,
            :html    => { :class => 'icon icon-time-add' },
            :if      => Proc.new { User.current.internal_client? && User.current.allowed_to_globally_view_all_time_entries? }

  menu.push :messages, '#',
            caption: EasyExtensions::MenuManagerProc.new { I18n.t(:label_message_plural).html_safe + '&nbsp;<i class=\'icon-arrow down\'></i>'.html_safe },
            html:    { class: 'icon icon-mail' },
            if:      Proc.new { User.current.internal_client? }

  menu.push :mail_to, :user_profile_menu_item_mail_to,
            parent:  :messages,
            caption: :button_send_email,
            html:    { class: 'icon icon-mail' },
            if:      Proc.new { User.current.internal_client? }
end


Redmine::MenuManager.map :easy_project_top_menu do |menu|
  menu.push :issue_new,
            { :controller => 'issues', :action => 'new' },
            :param   => :project_id,
            :caption => :label_issue_new,
            :html    => { :class => 'button-3 icon icon-add' },
            :if      => ->(project) {
              User.current.allowed_to?(:add_issues, project) && !User.current.easy_user_type_for?(:hide_new_issue_button) && project.module_enabled?(:issue_tracking) && project.available_trackers.any?
            }
end

Redmine::MenuManager.map :issue_sidebar_more_menu do |menu|
  menu.push :log_time, :link_to_issue_new_time_entry,
            caption: :button_log_time,
            html:    {
                class: 'button icon icon-time-add',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:sidebar_issue_button_log_time) },
                data:  { remote: true }
            },
            if:      -> issue {
              User.current.allowed_to?(:log_time, issue.project) && !(!EasyGlobalTimeEntrySetting.value('allow_log_time_to_closed_issue', User.current.roles_for_project(issue.project)) && issue.closed?)
            }
  menu.push :new_subtask, :link_to_issue_new_subtask,
            caption: :button_new_subtask,
            html:    {
                class: 'button icon icon-add',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:title_new_subtask) }
            },
            if:      -> issue { User.current.allowed_to?(:manage_subtasks, issue.project) }

  menu.push :copy, :link_to_issue_copy,
            caption: :button_copy,
            html:    {
                class: 'button icon icon-copy issue-copy',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:sidebar_issue_button_copy) }
            },
            if:      -> issue {
              User.current.allowed_to?(:add_issues, issue.project) && User.current.allowed_to?(:copy_issues, issue.project)
            }

  menu.push :delete, :issue_path,
            caption: :button_delete,
            html:    {
                class:         'button icon icon-del',
                title:         EasyExtensions::MenuManagerProc.new { I18n.t(:sidebar_issue_button_delete) },
                method:        :delete,
                'data-confirm' => EasyExtensions::MenuManagerProc.new {
                  I18n.t(:text_issues_destroy_confirmation)
                }
            },
            if:      -> issue { issue.deletable? }

  menu.push :move, :link_to_issue_move,
            caption: :button_move,
            html:    {
                class: 'button icon icon-move',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:sidebar_issue_button_move) }
            },
            if:      -> issue {
              issue.editable? && User.current.allowed_to?(:move_issues, issue.project)
            }

  menu.push :copy_as_subtask, :link_to_issue_copy_as_subtask,
            caption: :button_clone_as_subtask,
            html:    {
                class: 'button icon icon-copy issue-copy',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:sidebar_issue_button_clone_as_subtask) }
            },
            if:      -> issue {
              User.current.allowed_to?(:manage_subtasks, issue.project) && User.current.allowed_to?(:copy_issues, issue.project) && !issue.tracker.easy_distributed_tasks?
            }

  menu.push :merge, 'javascript:EASY.utils.showAndScrollTo("merge_to_form", -150, "merge-to-container");',
            caption: :button_merge,
            html:    {
                class: 'button icon icon-integrate',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:button_merge_to) }
            },
            if:      -> issue { User.current.allowed_to?(:edit_issues, issue.project) }

  menu.push :new_task_relation, 'javascript:EASY.utils.showAndScrollTo("new-relation-form", -150, "relations");',
            caption: :button_new_issue_relation,
            html:    {
                class: 'button icon icon-relation',
                title: EasyExtensions::MenuManagerProc.new { I18n.t(:title_new_issue_relation) }
            },
            if:      -> issue { User.current.allowed_to?(:manage_issue_relations, issue.project) }

end
