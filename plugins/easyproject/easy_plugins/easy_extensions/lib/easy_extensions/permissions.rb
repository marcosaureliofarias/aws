Redmine::AccessControl.update_permission :add_project, {}, :global => true
Redmine::AccessControl.update_permission :close_project, { :projects => [:bulk_close, :bulk_reopen] }
Redmine::AccessControl.update_permission :add_issues, { :my => [:new_my_page_create_issue], :issues => [:new_for_dialog] }
Redmine::AccessControl.update_permission :add_issue_notes, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :add_issue_watchers, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :delete_issues, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :delete_issue_watchers, {}, depends_on: [:view_issues, :view_issue_watchers]
Redmine::AccessControl.update_permission :edit_issue_notes, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :edit_own_issue_notes, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :set_notes_private, {}, depends_on: [:view_issues, :add_issue_notes]
Redmine::AccessControl.update_permission :add_documents, { :documents => [:select_project] }
Redmine::AccessControl.update_permission :edit_documents, { :documents => [:select_project] }
Redmine::AccessControl.update_permission :edit_issues, { :easy_issues => [:description_edit, :description_update, :edit_toggle_description] }, depends_on: :view_issues
Redmine::AccessControl.update_permission :edit_own_issues, { :easy_issues => [:description_edit, :description_update, :edit_toggle_description] }, depends_on: :view_issues
Redmine::AccessControl.update_permission :manage_issue_relations, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :manage_subtasks, { :easy_issues => [:remove_child] }, depends_on: :view_issues
Redmine::AccessControl.update_permission :manage_public_queries, {}, depends_on: :save_queries
Redmine::AccessControl.update_permission :manage_members, {}, depends_on: :edit_project
Redmine::AccessControl.update_permission :view_news, {}, { :public => false }

Redmine::AccessControl.update_permission :log_time, {
    easy_time_entries:
        [:index, :load_users, :load_assigned_projects, :load_assigned_issues, :load_fixed_activities, :create, :show, :new, :update, :change_projects_for_bulk_edit, :change_issues_for_bulk_edit, :change_role_activities, :personal_attendance_report],
    easy_issue_timers:
        [:play, :stop, :pause, :destroy]
}
Redmine::AccessControl.update_permission :edit_time_entries, { easy_time_entries: [:edit, :update, :destroy, :bulk_edit, :bulk_update] }, require: :member
Redmine::AccessControl.update_permission :edit_own_time_entries, { easy_time_entries: [:edit, :update, :destroy, :bulk_edit, :bulk_update] }, require: :loggedin
Redmine::AccessControl.update_permission :view_issue_watchers, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :view_time_entries, { easy_time_entries: [:index, :load_users, :load_assigned_projects, :load_assigned_issues, :load_fixed_activities, :select_issue, :report, :show, :overview] }, global: true
Redmine::AccessControl.update_permission :view_private_notes, {}, depends_on: :view_issues
Redmine::AccessControl.update_permission :view_project, { :projects => [:load_allowed_parents, :favorite], :activities => [] }
Redmine::AccessControl.update_permission :manage_categories, { :issue_categories => [:move_category] }, depends_on: :edit_project
Redmine::AccessControl.update_permission :view_issues, { :easy_issues => [:find_by_user, :favorite, :render_tab] }
Redmine::AccessControl.update_permission :copy_issues, {}, depends_on: [:view_issues, :add_issues]
Redmine::AccessControl.update_permission :select_project_modules, { projects: [:easy_custom_menu_toggle, :bulk_modules],
                                                                    easy_custom_project_menus: [:index, :show, :new, :create, :edit, :update, :destroy] },
                                                                  depends_on: :edit_project
Redmine::AccessControl.update_permission :save_queries, { :easy_queries => [:new, :create, :edit, :update, :destroy] }, :require => :loggedin
Redmine::AccessControl.update_permission :set_issues_private, {}, depends_on: [:view_issues, :edit_issues]
Redmine::AccessControl.update_permission :set_own_issues_private, {}, depends_on: [:view_issues, :edit_issues]
Redmine::AccessControl.update_permission :manage_versions, { :versions => [:bulk_destroy] }, depends_on: :edit_project

Redmine::AccessControl.permission_acts_as_admin(:view_time_entries, Proc.new { |user| user.pref.global_time_entries_visibility })

Redmine::AccessControl.remove_permission :import_issues
Redmine::AccessControl.remove_permission :import_time_entries
Redmine::AccessControl.remove_permission :log_time_for_other_users # :add_timeentries_for_other_users & :add_timeentries_for_other_users_on_project

Redmine::AccessControl.map do |map|

  map.permission :manage_page_project_overview, { :projects => :personalize_show }

  map.permission :archive_project, { :projects => [:archive, :unarchive, :bulk_archive, :bulk_unarchive] }, :read => true
  map.permission :delete_project, { :projects => [:destroy, :bulk_destroy] }, depends_on: :edit_project
  map.permission :edit_own_projects, { :projects => [:settings, :edit, :update, :easy_custom_menu_toggle], :easy_custom_project_menus => [:index, :show, :new, :create, :edit, :update, :destroy] }, :require => :loggedin, :global => true
  map.permission :edit_project_custom_fields, { :projects => [:edit_custom_fields_form, :update_custom_fields_form] }, :require => :member, depends_on: :edit_project
  map.permission :create_project_from_template, { :templates => :index }, :read => true, :global => true
  map.permission :create_subproject_from_template, { :templates => :index }, :read => true
  map.permission :create_project_template, { :templates => [:new, :create] }, depends_on: :edit_project
  map.permission :edit_project_template, {}, :global => true
  map.permission :delete_project_template, { :templates => [:destroy, :bulk_destroy] }, :global => true
  map.permission :view_project_activity, { :activities => [:index], :easy_activities => [:show_toolbar, :show_selected_event_type, :discart_all_events, :events_from_activity_feed_module, :get_current_user_activities_count] }, :read => true
  map.permission :copy_project, { :projects => [:copy] }, :read => true, depends_on: :edit_project
  map.permission :view_project_overview_users_query, {}, :read => true, :global => true
  map.permission :manage_bulk_version, { :versions => [:bulk_edit, :bulk_update] }, depends_on: [:edit_project, :manage_versions]

  map.permission :manage_global_versions, { :easy_versions => [:index, :new, :create, :overview, :overview_layout] }, :global => true

  map.permission :manage_easy_issue_timers, { :easy_issue_timers => [:settings, :update_settings] }, depends_on: :edit_project


  # map.permission :manage_easy_broadcasts, {easy_broadcasts: [:index, :show, :new, :create, :edit, :update, :destroy, :context_menu] }, global: true

  map.project_module :issue_tracking do |pmap|
    # pmap.permission :view_restrictions_users, {}, :read => true
    pmap.permission :edit_assigned_issue, { :issues      => [:edit, :update, :bulk_edit, :bulk_update],
                                            :easy_issues => [:description_edit, :description_update, :edit_toggle_description], :attachments => :upload },
                                          depends_on: :view_issues
    pmap.permission :move_issues, { :issue_moves => [:available_issues], :easy_issues => [:move_to_project] }, depends_on: [:view_issues, :edit_issues]
    pmap.permission :edit_repeating_options_on_issue, {}, depends_on: [:view_issues, :edit_issues]
    pmap.permission :edit_without_notifications, {}, depends_on: [:view_issues, :edit_issues, :add_issue_notes]
    pmap.permission :edit_issue_fixed_activity, {}, depends_on: [:view_issues, :edit_issues]
  end

  map.project_module :news do |pmap|
    pmap.permission :manage_own_news, { :news => [:new, :create, :edit, :update, :destroy], :comments => [:destroy], :attachments => :upload }, :require => :member
    pmap.permission :manage_comments, :global => true
    pmap.permission :delete_own_comments, :global => true
  end

  map.project_module :time_tracking do |pmap|
    pmap.permission :view_personal_statement, { :easy_time_entries => :index }, :read => true, :global => true
    pmap.permission :view_estimated_hours, {}, :read => true
    pmap.permission :add_timeentries_for_other_users, {}, :global => true
    pmap.permission :add_timeentries_for_other_users_on_project, {}
    pmap.permission :timelog_can_easy_locking, { :easy_time_entries => :resolve_easy_lock }, :global => true
    pmap.permission :timelog_can_easy_unlocking, { :easy_time_entries => :resolve_easy_lock }, :global => true
  end

  map.project_module :easy_attendances do |pmap|
    pmap.permission :view_easy_attendances, { :easy_attendances => [:index, :show, :report, :statuses, :overview], journals: [:diff] }, :read => true, :require => :loggedin, :global => true
    pmap.permission :use_easy_attendances, { :easy_attendances => [:new, :create, :edit, :update, :arrival, :departure, :bulk_update, :check_vacation_limit] }, :require => :loggedin, :global => true
    pmap.permission :edit_easy_attendances, { :easy_attendances => [:edit, :bulk_update, :arrival, :departure] }, :require => :loggedin, :global => true
    pmap.permission :cancel_own_easy_attendances, { :easy_attendances => [:bulk_cancel] }, :require => :loggedin, :global => true
    pmap.permission :delete_easy_attendances, { :easy_attendances => [:destroy, :bulk_destroy] }, :require => :loggedin, :global => true
    pmap.permission :delete_own_easy_attendances, { :easy_attendances => [:destroy, :bulk_destroy] }, :require => :loggedin, :global => true
    pmap.permission :view_easy_attendances_extra_info, {}, :read => true, :global => true
    pmap.permission :view_easy_attendance_other_users, { :easy_attendances => [:detailed_report] }, :read => true, :global => true
    pmap.permission :edit_easy_attendance_approval, { :easy_attendances => [:edit, :approval_save, :approval, :check_vacation_limit] }, :global => true
  end

  map.project_module :easy_other_permissions do |pmap|
    pmap.permission :view_easy_resource_booking_module, { :easy_resource_availabilities => [:index] }, :global => true
    pmap.permission :manage_easy_resource_booking_module, { :easy_resource_availabilities => [:layout] }, :global => true
    pmap.permission :manage_easy_resource_booking_availability, {}, :global => true
    pmap.permission :manage_my_page, { :my => [:page_layout] }, :global => true
    pmap.permission :edit_profile, { :my => [:account, :change_avatar] }, :global => true
    pmap.permission :view_issue_timers_of_others, {}, :global => true
    pmap.permission :view_custom_dashboards, { :easy_pages => [:custom_easy_page] }, :global => true
    pmap.permission :manage_custom_dashboards, { :easy_pages => [:custom_easy_page, :custom_easy_page_layout] }, :global => true
  end

end
