root :to => 'my#page' #, :as => 'home'

mount ActionCable.server => '/cable'

match '/', :to => lambda { |env| [405, {}, [env.to_s]] }, :via => [:propfind, :options]

get 'my/page_layout', :to => 'my#page_layout'
get 'easy_page_layout/layout_from_template_add_replace', :to => 'easy_page_layout#layout_from_template_add_replace'
post 'easy_page_layout/layout_from_template_built_in', :to => 'easy_page_layout#layout_from_template_built_in'

# account
get 'account/autologin', :to => 'account#autologin'
get 'autologin', :to => 'account#autologin'
match 'sso_login', to: 'easy_sso_login#sso_login', via: [:get, :post], as: 'sso_login'
get 'sso_autologin', to: 'account#sso_autologin'
get 'sso_variables', to: 'account#sso_variables'
get 'quotes.:format', :to => 'account#quotes', :as => 'login_quotes'
post 'account/reset_easy_digest_token', :to => 'account#reset_easy_digest_token'

# admin
get 'admin/manage_plugins', :to => 'admin#manage_plugins'
post 'admin/projects', :to => 'admin#projects'


get 'admin/version(.:format)', to: 'admin/easy_admin#version'
get 'admin/enabled_plugins', to: 'admin/easy_admin#enabled_plugins'

mount EasyMonitoring::Engine, at: "/"

namespace :admin do
  resources :easy_settings
end

# api_custom_fields
resources :api_custom_fields

# api_enumerations
get 'api_enumerations', :to => 'api_enumerations#index'

# api_members
get 'api_members/projects/:project_id.:format', :to => 'api_members#index'
get 'api_members/projects/:project_id/:id.:format', :to => 'api_members#show'
post 'api_members/projects/:project_id.:format', :to => 'api_members#create'
put 'api_members/projects/:project_id/:id.:format', :to => 'api_members#update'
delete 'api_members/projects/:project_id/:id.:format', :to => 'api_members#destroy'

# api_roles
get 'api_roles.:format', :to => 'api_roles#index'
get 'api_roles/:id.:format', :to => 'api_roles#show'
post 'api_roles.:format', :to => 'api_roles#create'
put 'api_roles/:id.:format', :to => 'api_roles#update'
delete 'api_roles/:id.:format', :to => 'api_roles#destroy'

# attachments
get 'attachments/show', :controller => 'attachments'
get 'attachments/bulk_download_as_zip', :to => 'attachments#bulk_download_as_zip'
delete 'attachments/bulk_destroy', to: 'attachments#bulk_destroy'
resources :attachments do
  member do
    match :destroy_version, via: [:get, :post, :delete]
    match :revert_to_version, via: [:get, :post]
    get :attachment_custom_fields
    get :webdav_modal
  end
end
get 'attachments/attach/:entity_type/:entity_id', :to => 'attachments#new', :as => 'new_attachment_for_entity'
get 'attachments/attach/:id', :to => 'attachments#new_version', :as => 'new_attachment_version'
post 'attachments/attach/:entity_type/:entity_id', :to => 'attachments#attach'
post 'attach', :to => 'attachments#attach'

# auth
get 'auth/sso_easysoftware_com/callback' => 'easy_oauth_callbacks#sso_easysoftware_com'
get 'auth/failure' => 'easy_oauth_callbacks#failure'

match 'easy_oauth/authorize' => 'easy_oauth#authorize', via: [:get, :post]
match 'easy_oauth/token' => 'easy_oauth#token', via: [:get, :post]
match 'easy_oauth/user' => 'easy_oauth#user', via: [:get, :post]

# auth_sources
match 'auth_sources/:id/move_users', :to => 'auth_sources#move_users', :via => :get
match 'auth_sources(/:id)/available_attributes', :to => 'auth_sources#available_attributes', :as => 'available_attributes_auth_source', :via => [:patch, :put, :post, :get]
get 'auth_sources/:id/available_users', :to => 'auth_sources#available_users', :as => 'available_users_auth_source'
get 'auth_sources/reload_easy_options_projects_and_roles', :to => 'auth_sources#reload_easy_options_projects_and_roles'

# bulk_time_entries
get 'bulk_time_entries', :to => 'bulk_time_entries#index', :as => 'bulk_time_entries'
match 'bulk_time_entries', :to => 'bulk_time_entries#save', via: [:post, :patch]
get 'bulk_time_entries/load_users.:format', :to => 'bulk_time_entries#load_users'
get 'bulk_time_entries/load_assigned_projects.:format', :to => 'bulk_time_entries#load_assigned_projects'
get 'bulk_time_entries/load_assigned_issues.:format', :to => 'bulk_time_entries#load_assigned_issues'
get 'bulk_time_entries/load_fixed_activities.:format', :to => 'bulk_time_entries#load_fixed_activities'
get 'bulk_time_entries/:time_entry_id', :to => 'bulk_time_entries#show'

# comments
get 'comments/:entity_type/:entity_id', :to => 'comments#new', :as => 'new_comment'
post 'comments/:entity_type/:entity_id', :to => 'comments#create', :as => 'add_comment'
delete 'comments/:comment_id', :to => 'comments#destroy', :as => 'remove_comment'

# context_menus
get 'context_menus/versioned_attachments' => 'context_menus#versioned_attachments'
get 'context_menus/versions', :to => 'context_menus#versions'
get 'context_menus/easy_attendances', :to => 'context_menus#easy_attendances'
get 'context_menus/projects', :to => 'context_menus#projects'
get 'context_menus/templates', :to => 'context_menus#templates', :as => 'templates_context_menu'
get 'context_menus/easy_rake_tasks', :to => 'context_menus#easy_rake_tasks'
get 'context_menu/admin_users/', :to => 'context_menus#admin_users', :as => 'admin_users_context_menu'

# custom_fields
match 'custom_fields/:id/toggle_disable' => 'custom_fields#toggle_disable', :as => 'custom_field_toogle_disable', via: [:get, :post]
get 'custom_fields/:id/edit_long_text', :to => 'custom_fields#edit_long_text', :as => 'custom_fields_edit_long_text'
match 'custom_fields/update_form', :to => 'custom_fields#update_form', :as => 'update_form_custom_fields', via: [:post, :put]

# documents
post 'documents/create', :to => 'documents#create'

# easy_documents
get 'documents', :to => 'easy_documents#index'
get 'documents/new', :to => 'easy_documents#new'
get 'documents/select_project', :to => 'easy_documents#select_project'
get 'documents/:id/new_attachment', :to => 'easy_documents#new_attachments', :as => 'new_attachment_document'


# easy activities
get 'easy_activity/', :to => 'easy_activities#index', :as => 'easy_activities'
get 'easy_activity/toolbar', :to => 'easy_activities#show_toolbar', :as => 'easy_activities_toolbar'
get 'easy_activity/show_selected_event_type', :to => 'easy_activities#show_selected_event_type', :as => 'easy_show_selected_event_type'
delete 'easy_activity/discart_all_events', :to => 'easy_activities#discart_all_events', :as => 'easy_discart_all_events'
get 'easy_activity/events_from_activity_feed_module', :to => 'easy_activities#events_from_activity_feed_module', :as => 'easy_events_from_activity_feed_module'
get 'get_current_user_activities_count', :to => 'easy_activities#get_current_user_activities_count', :as => 'get_current_user_activities_count'

# easy_attendances
match 'easy_attendances/overview', :to => 'easy_attendances#overview', :via => [:get, :post, :put], :as => 'easy_attendances_overview'
match 'easy_attendances/layout', :to => 'easy_attendances#layout', :via => [:get, :post]
# easy_attendance_settings
match 'easy_attendances/settings', :to => 'easy_attendance_settings#index', :via => [:get], :as => 'easy_attendance_settings'
match 'easy_attendances/settings', :to => 'easy_attendance_settings#plugin_settings', :via => [:post], :as => 'plugin_settings_easy_attendance_settings'
resources :easy_attendances do

  collection do
    post :change_activity
    delete :bulk_destroy
    put :bulk_update
    match :report, :via => [:get, :post]
    get :detailed_report
    get :new_notify_after_arrived
    get :approval
    post :approval_save
    post :new_notify_after_arrived, :to => 'easy_attendances#create_notify_after_arrived'
    get :arrival
    get :statuses
    post :bulk_cancel
    match :check_vacation_limit, via: [:post, :patch]
  end

  member do
    get :departure
  end
end

# easy_attendance_activities
resources :easy_attendance_activities do
  member do
    match :move_attendances, :via => [:get, :post]
  end
  collection do
    match :reload_time_entry_activities, :via => [:get, :post, :patch]
    post :set_user_attendace_activity_limits, :to => 'easy_attendance_activities#set_user_attendace_activity_limits'
  end
end

# easy_avatars
resource :easy_avatar, :only => [:create, :destroy] do
  collection do
    get :crop, :action => 'crop_avatar'
    post :crop, :action => 'save_avatar_crop'
  end
end

# easy_auto_completes
get 'easy_autocompletes/:autocomplete_action', :to => "easy_auto_completes#index", :as => 'easy_autocomplete', :defaults => { :format => 'json' }

# easy_broadcasts
resources :easy_broadcasts do
  collection do
    get 'context_menu'
    get 'active_broadcasts'
    post 'mark_as_read'
    delete :index, action: :destroy
  end
end

# easy_cache
match "easy_cache/delete_all", :to => "easy_cache#delete_all", :via => [:get, :post, :put, :delete]

get 'easy_community', to: 'easy_community#log_in', as: 'easy_community'

get 'easy_entity_assignments', to: 'easy_entity_assignments#index', as: 'easy_entity_assignments'
post 'easy_entity_assignments', to: 'easy_entity_assignments#update'
delete 'easy_entity_assignments', to: 'easy_entity_assignments#destroy'

get 'easy_entity_replacable_tokens/list', :to => 'easy_entity_replacable_tokens#list', :as => 'list_easy_entity_replacable_tokens'

match 'easy_entity_actions/update_form', :to => 'easy_entity_actions#update_form', :via => [:post, :put], :as => 'easy_entity_action_update_form'

resources :easy_entity_actions do
  member do
    get 'execute_all'
    get 'execute'
  end
end

#easy_entity_maps
resources :easy_entity_attribute_maps, :except => [:show, :edit, :update]

# easy_external_emails
get 'easy_external_emails/preview', :to => 'easy_external_emails#preview_external_email', :via => [:get, :patch], :as => 'preview_external_email'
post 'easy_external_emails/preview', :to => 'easy_external_emails#send_external_email', :as => 'send_external_email'

# easy_pdf_themes
resources :easy_pdf_themes

# easy_user_types
resources :easy_user_types do
  collection do
    put :reorder_custom_menus
  end
end


# easy_issues
get 'easy_issues/:id/description_edit.:format', to: 'easy_issues#description_edit', as: :easy_issues_description_edit
post 'easy_issues/:id/description_update', :to => 'easy_issues#description_update'
match 'easy_issues/load_assigned_projects.:format', :to => 'easy_issues#load_assigned_projects', :via => [:get, :post]
match 'easy_issues/dependent_fields', :to => 'easy_issues#dependent_fields', :via => [:get, :post]
delete 'easy_issues/:id/remove_child/:child_id', :to => 'easy_issues#remove_child'
get 'easy_issues/:id/toggle_description/:element', :to => 'easy_issues#toggle_description'
get 'easy_issues/:id/load_repeating', :to => 'easy_issues#load_repeating', :as => 'easy_issues_load_repeating'
get 'easy_issues/:id/load_history', :to => 'easy_issues#load_history'
get 'easy_issues/find_by_user', :to => 'easy_issues#find_by_user'
get 'easy_issues/move_to_project', to: 'easy_issues#move_to_project', as: 'issue_move_to_project'
post 'easy_issues/:id/favorite', :to => 'easy_issues#favorite', :as => 'favorite_issue'

# easy_issue_timers
get 'easy_issue_timers/settings', :to => 'easy_issue_timers#settings'
get 'easy_issue_timers(.:format)', :to => 'easy_issue_timers#get_current_user_timers', :as => :get_current_user_timers
put 'easy_issue_timers/settings', :to => 'easy_issue_timers#update_settings'
post 'issues/:id/play', :to => 'easy_issue_timers#play', :as => :easy_issue_timer_play
post 'issues/:id/stop/:timer_id', :to => 'easy_issue_timers#stop', :as => :easy_issue_timer_stop
post 'issues/:id/pause/:timer_id', :to => 'easy_issue_timers#pause', :as => :easy_issue_timer_pause
delete 'easy_issue_timers/:id', :to => 'easy_issue_timers#destroy', :as => :easy_issue_timer
match 'easy_issues(/:project_id)/fields(/:id).:format', :to => 'easy_issues#form_fields', :via => [:get, :post], :as => 'form_fields'
match 'easy_issues(/:project_id)/fields_v2(/:id).:format', :to => 'easy_issues#form_fields_v2', :via => [:get, :post], :as => 'form_fields_v2'
# issue categories
put 'issue_categories/:id/move', :to => 'issue_categories#move_category'

get 'easy_licenses', :to => 'easy_licenses#index', :as => 'easy_licenses'
post 'easy_licenses', :to => 'easy_licenses#update', :as => 'update_easy_license'
get 'easy_licenses/validate', :to => 'easy_licenses#validate', :as => 'validate_easy_license'

# easy_pages
resources :easy_pages, constraints: { id: /\d+/ }
scope :easy_pages, controller: :easy_pages, as: :easy_pages do
  get 'built_in'
end
constraints identifier: /(?!\d+$)[a-z0-9\-_]*/ do
  get 'easy_pages/:identifier', to: 'easy_pages#custom_easy_page', as: 'custom_easy_page'
  match 'easy_pages/:identifier/layout', to: 'easy_pages#custom_easy_page_layout', via: [:get, :post], as: 'custom_easy_page_layout'
end

# easy_page_layout
scope :easy_page_layout, controller: :easy_page_layout, as: :easy_page_layout do
  match 'add_module', via: [:get, :post]
  match 'clone_module', via: [:get, :post]
  get 'clone_module_choose_target_tab'
  match 'order_module', via: [:get, :post]
  match 'remove_module', via: [:get, :post, :delete]
  match 'save_module', via: [:get, :post]
  match 'layout_from_template', via: [:get, :post]
  match 'layout_from_template_selecting_projects', via: [:get, :post]
  match 'layout_from_template_selected_projects', via: [:get, :post]
  match 'layout_from_template_selecting_users', via: [:get, :post]
  match 'layout_from_template_selected_users', via: [:get, :post]
  match 'layout_from_template_to_all', via: [:get, :post]
  match 'save_grid', via: [:post]
  get 'get_tab_content'
  match 'show_tab', via: [:get, :post]
  match 'add_tab', via: [:get, :post]
  match 'edit_tab', via: [:get, :post]
  match 'save_tab', via: [:put]
  match 'remove_tab', via: [:delete]
  get 'get_group_entities'
  get 'toggle_members'
end

# easy_page_module_translations
scope :easy_page_module_translations, controller: :easy_page_module_translations, as: :easy_page_module_translations do
  post :index
  post :add
end

resources :easy_page_tabs, only: [] do
  member do
    get :get_content
  end
end

resources :easy_page_template_tabs, only: [] do
  member do
    get :get_content
  end
end

# easy_page_template_layout
match 'easy_page_template_layout/add_module', :to => 'easy_page_template_layout#add_module', :via => [:get, :post]
match 'easy_page_template_layout/clone_module', :to => 'easy_page_template_layout#clone_module', :via => [:get, :post]
get 'easy_page_template_layout/clone_module_choose_target_tab', to: 'easy_page_template_layout#clone_module_choose_target_tab'
match 'easy_page_template_layout/order_module', :to => 'easy_page_template_layout#order_module', :via => [:get, :post]
match 'easy_page_template_layout/remove_module', :to => 'easy_page_template_layout#remove_module', :via => [:get, :post, :delete]
match 'easy_page_template_layout/save_module', :to => 'easy_page_template_layout#save_module', :via => [:get, :post]
match 'easy_page_template_layout/save_grid', :to => 'easy_page_template_layout#save_grid', :via => [:post]
match 'easy_page_template_layout/show_tab', :to => 'easy_page_template_layout#show_tab', :via => [:get, :post]
match 'easy_page_template_layout/add_tab', :to => 'easy_page_template_layout#add_tab', :via => [:get, :post]
match 'easy_page_template_layout/edit_tab', :to => 'easy_page_template_layout#edit_tab', :via => [:get, :post]
match 'easy_page_template_layout/save_tab', :to => 'easy_page_template_layout#save_tab', :via => [:put]
match 'easy_page_template_layout/remove_tab', :to => 'easy_page_template_layout#remove_tab', :via => [:delete]
get 'easy_page_template_layout/get_tab_content', :to => 'easy_page_template_layout#get_tab_content'
get 'easy_page_template_layout/get_group_entities', :to => 'easy_page_template_layout#get_group_entities'

# easy_page_templates
match 'easy_page_templates/move', :to => 'easy_page_templates#move', :via => [:get, :post]
match 'easy_page_templates/show_page_template', :to => 'easy_page_templates#show_page_template', :via => [:get, :post]
match 'easy_page_templates/edit_page_template', :to => 'easy_page_templates#edit_page_template', :via => [:get, :post]
resources :easy_page_templates

# easy_chart_baselines
get 'easy_page_zone_modules/:module_uuid/easy_chart_baselines', to: 'easy_chart_baselines#index'
get 'easy_chart_baselines/:id', to: 'easy_chart_baselines#show', as: :easy_chart_baseline
delete 'easy_chart_baselines/:id', to: 'easy_chart_baselines#destroy'
post 'easy_page_zone_modules/:module_uuid/easy_chart_baselines', to: 'easy_chart_baselines#create'

# easy_page_zones
match 'easy_page_zones/assign_zone', :to => 'easy_page_zones#assign_zone', :via => [:get, :post]
resources :easy_page_zones

# easy_qr
get 'easy_qr', :to => 'easy_qr#generate', :as => 'easy_qr'

# easy_queries
resources :easy_queries do
  collection do
    match 'easy_document_preview', via: [:get, :post]
    match 'preview', via: [:get, :post]
    match 'modal_for_trend', via: [:get, :post]
    get 'entities' #get query data
    get 'filters'
    get 'filters_custom_formatting'
    match 'chart', via: [:get, :post]
    match 'calendar', via: [:get, :post]
    get 'find_by_easy_query'
    match 'filter_values', via: [:get, :post]
    get 'output_data'
  end
  post 'copy_to_users'
  get 'load_users_for_copy'
end

# easy_query_settings
resources :easy_query_settings, :only => [:index] do
  collection do
    match :setting, :via => [:get, :post]
    match :save, :via => [:get, :post]
  end
end

# easy_rating_info
get 'easy_rating_info/:id', :to => 'easy_rating_info#show'

# easy_rake_tasks
resources :easy_rake_tasks do
  member do
    get 'execute'
    get 'task_infos'
    get 'easy_rake_task_info_detail_receive_mail'
    post 'easy_rake_task_easy_helpdesk_receive_mail_status_detail'
  end
  collection do
    match 'test_mail', :via => [:get, :post, :put]
    match 'imap_folders', :via => [:get, :post, :put]
    get 'execute_tasks'
  end
end

# easy_resource_availabilities
post 'easy_resource_availabilities/update', :to => 'easy_resource_availabilities#update'
get 'easy_resource_availabilities', :to => 'easy_resource_availabilities#index'
get 'easy_resource_availabilities/page_layout', :to => 'easy_resource_availabilities#layout'

resources :easy_short_urls do
  collection do
    get 'actions'
  end
end
get 's/:shortcut', :to => 'easy_short_urls#shortcut', :as => 'easy_shortcut'

# easy_sliding_panel
post 'easy_sliding_panels/save_location', :to => 'easy_sliding_panels#save_location'

get 'easy_taggables/autocomplete', :to => 'easy_taggables#autocomplete', :as => 'autocomplete_easy_taggables'
post 'easy_taggables', :to => 'easy_taggables#save_entity', :as => 'save_entity_easy_taggables'
get 'easy_tags', :to => 'easy_taggables#index', :as => 'easy_tags'
get 'easy_tags/:tag_name', :to => 'easy_taggables#tag', :as => 'easy_tag'
delete 'easy_tags/:tag_name', :to => 'easy_taggables#destroy', :as => 'destroy_easy_tag'

# easy_translations
get 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#index', :as => 'easy_translations'
put 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#update', :as => 'update_easy_translations'
post 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#create', :as => 'create_easy_translations'
delete 'easy_translations/:id', :to => 'easy_translations#destroy', :as => 'destroy_easy_translation'

# easy_user_working_time_calendars
resources :easy_user_working_time_calendars do
  collection do
    match 'assign_to_user', :to => 'easy_user_working_time_calendars#assign_to_user', :via => [:get, :post]
    post 'mass_exceptions', :to => 'easy_user_working_time_calendars#mass_exceptions'
  end
  member do
    match 'inline_edit', :to => 'easy_user_working_time_calendars#inline_edit', :via => [:get, :post]
    match 'inline_update', :to => 'easy_user_working_time_calendars#inline_update', :via => [:get, :post]
    match 'inline_show', :to => 'easy_user_working_time_calendars#inline_show', :via => [:get, :post]
    match 'reset', :to => 'easy_user_working_time_calendars#reset', :via => [:get, :post]
  end
end

# easy_user_time_calendar_holidays
resources :easy_user_time_calendar_holidays, except: [:show]

# easy_user_time_calendar_exceptions
resources :easy_user_time_calendar_exceptions
get 'exceptions_from_calendar/:calendar_id', :to => 'easy_user_time_calendar_exceptions#exceptions_from_calendar'

# easy_versions - global versions
get 'versions/new', :to => 'easy_versions#new'
post 'versions/create', :to => 'versions#create'
resources :easy_versions do
  collection do
    get 'overview'
    get 'overview_layout'
  end
end
get 'versions' => 'easy_versions#index'

# issues
match 'issues/:id/render_preview', :to => 'easy_issues#render_preview', :via => [:get, :post], :as => 'issue_render_preview'
match 'issues/update_form', :controller => 'issues', :action => 'update_form', :via => [:get, :post]
get 'issues/new', :to => 'easy_issues#new'
get 'issues/new_for_dialog', :to => 'easy_issues#new_for_dialog'
get 'projects/:project_id/issues/new_for_dialog', :to => 'easy_issues#new_for_dialog', :as => 'issue_from_gantt'
get 'issues/:id/render_tab', :to => 'easy_issues#render_tab', :as => 'issue_render_tab'
match 'issues/preview/new', :to => 'previews#issue', :via => [:get, :post, :put]
match 'issues/:id/preview_external_email', :to => 'easy_external_emails#preview_external_email', :defaults => { :entity_type => 'Issue' }, :as => 'issue_preview_external_email', :via => [:get, :patch]

post 'issues/:id/preview_external_email', :to => 'easy_external_emails#send_external_email', :as => 'issue_send_external_email'

resources :issues, :only => [:index, :new, :create] do
  resources :time_entries, controller: 'easy_time_entries'
end

# issue_statuses
get 'issue_statuses/:id/edit_reassignment', :to => 'issue_statuses#edit_reassignment', :as => 'issue_status_edit_reassignment'
post 'issue_statuses/:id/update_reassignment', :to => 'issue_statuses#update_reassignment', :as => 'issue_status_update_reassignment'

# journals
post 'journals/:id/public', :to => 'journals#public_journal', :as => 'public_journal'
get 'journals/load_journals', :to => 'journals#load_journals', :as => 'load_journals'

# my
match 'my/update_my_page_new_issue_dependent_fields', :to => 'my#update_my_page_new_issue_dependent_fields', :via => [:get, :post]
match 'my/update_my_page_new_issue_attributes', :to => 'my#update_my_page_new_issue_attributes', :via => [:get, :post]
post 'my/new_my_page_create_issue', :to => 'my#new_my_page_create_issue'
get 'my/new_my_page_create_issue', :to => 'my#page'
match 'my/update_my_page_module_view(/:uuid)', :to => 'my#update_my_page_module_view', :as => 'update_my_page_module_view', :via => [:get, :post]
post 'my/save_my_page_module_view(/:uuid)', :to => 'my#save_my_page_module_view', :as => 'save_my_page_module_view'
match 'my/toggle_mobile_view', :to => 'my#toggle_mobile_view', :via => [:get, :post]
match 'my/toggle_mobile_view', :to => 'my#toggle_mobile_view', :via => [:get, :post]
get 'my/mobile_page_layout', :to => 'my#mobile_page_layout'
get 'login_or_logout', :to => 'my#login_or_logout'
get 'force_user_logout', :to => 'my#force_user_logout'
get 'force_user_login', :to => 'my#force_user_login'
match 'my/account', :to => 'my#account', :as => 'my_account', :via => [:get, :post]
get 'my/change_avatar', :to => 'my#change_avatar', :as => 'my_change_avatar'

# password
match 'password/password', :to => 'password#password', :via => [:get, :post]

# projects
get 'projects/my.:format', :to => 'projects#my'
post 'projects/:id/favorite', :to => 'projects#favorite', :as => 'favorite_project'
match 'projects/:id/personalize_show', :to => 'projects#personalize_show', :via => [:get, :post]
match 'projects/toggle_custom_fields_on_project_form', :to => 'projects#toggle_custom_fields_on_project_form', :as => 'toggle_project_custom_fields', :via => [:put, :post]
match 'projects/:project_id/versions/bulk_edit', :to => 'versions#bulk_edit', :via => [:get, :post]
put 'projects/:project_id/versions/bulk_update', :to => 'versions#bulk_update'
delete 'projects/:project_id/versions/bulk_destroy', :to => 'versions#bulk_destroy'
get 'projects/:project_id/easy_queries/new', :controller => 'easy_queries', :action => 'new'

match 'projects/:id/issues/report', to: "application#render_404", via: [:get, :post]
match 'projects/:id/issues/report/:detail', to: "application#render_404", via: [:get, :post]

# versions
match 'versions/bulk_edit', :to => 'versions#bulk_edit', :via => [:get, :post]
put 'versions/bulk_update', :to => 'versions#bulk_update'

resources :projects do
  member do
    post 'settings(/:tab)', :action => 'settings', as: 'projects_settings'
    get 'edit_custom_fields_form', :to => 'projects#edit_custom_fields_form', :as => 'edit_custom_fields_form'
    put 'edit_custom_fields_form', :to => 'projects#update_custom_fields_form', :as => 'update_custom_fields_form'
    post 'easy_custom_menu_toggle', :to => 'projects#easy_custom_menu_toggle', :as => 'easy_custom_menu_toggle'
    put 'update_history', :to => 'projects#update_history', :as => 'update_history'
    match 'show_more_members', to: 'projects#show_more_members', via: [:get, :post]
    post 'modules'
  end

  collection do
    get 'project_for_new_entity'
    match 'load_allowed_parents', :via => [:get, :post]
    delete 'bulk_destroy', :to => 'projects#bulk_destroy'
    post 'bulk_close', :to => 'projects#bulk_close'
    post 'bulk_reopen', :to => 'projects#bulk_reopen'
    post 'bulk_archive', :to => 'projects#bulk_archive'
    post 'bulk_unarchive', :to => 'projects#bulk_unarchive'
    post 'bulk_modules'
  end

  resources :easy_entity_actions
  resources :easy_custom_project_menus
end

# project_mass_copy
get 'project_mass_copy/select_source_project', :to => 'project_mass_copy#select_source_project'
get 'project_mass_copy/:source_project_id/select_target_projects', :to => 'project_mass_copy#select_target_projects'
post 'project_mass_copy/:source_project_id/select_actions', :to => 'project_mass_copy#select_actions'
post 'project_mass_copy/:source_project_id/copy', :to => 'project_mass_copy#copy'

# Queries
get 'queries.:format', { :controller => 'easy_queries', :action => 'index', :type => 'EasyIssueQuery' }

# RSS
match "rss/issues", :to => "rss#issues", :as => "issues_rss", :via => [:get, :post, :put, :delete]

match 'easy_repeating/:entity_type(/:entity_id)', :to => 'easy_repeating#show_repeating_options', :as => 'show_repeating_options', :via => [:get, :post]
delete 'easy_repeating/:entity_type/:entity_id', :to => 'easy_repeating#disable_easy_repeating', :as => 'disable_easy_repeating'

# roles
match 'roles/:id/move_members', :to => 'roles#move_members', :via => [:get, :post], :as => 'role_move_members'

# modal_selectors
match 'modal_selectors/:entity_action', :to => "modal_selectors#index", :as => 'modal_selectors', :via => [:get, :post, :put, :delete]

# settings
match 'settings/uninstall', :to => 'settings#uninstall', :via => [:get, :post]
match 'settings/release_cache', :to => 'settings#release_cache', :via => [:get, :post]
post 'settings/webdav_delete_locks', :to => 'settings#webdav_delete_locks'


# sidekiq
require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'easy_extensions/easy_admin_constraint'
#require 'sidekiq-scheduler/web'
mount Sidekiq::Web => '/easy/sidekiq', constraints: EasyAdminConstraint.new


# global time entry settings
resources :easy_global_time_entry_settings

# sys
match 'sys/git_fetcher', :to => 'sys#git_fetcher', :via => [:get, :post]

# templates
get 'templates', :to => 'templates#index'
get 'templates/:id/restore', :to => 'templates#restore'
get 'templates/:id/add', :to => 'templates#add'
get 'templates/:id/create', :to => 'templates#show_create_project', :as => 'show_create_project_template'
get 'templates/:id/copy', :to => 'templates#show_copy_project'
post 'templates/:id/create', :to => 'templates#make_project_from_template', as: 'make_project_from_template'
get 'templates/render_shifted_time_duration', to: 'templates#render_shifted_time_duration', as: 'render_shifted_time_duration'
post 'templates/:id/copy', :to => 'templates#copy_project_from_template', as: 'copy_project_from_template'
match 'templates/:id/destroy', :to => 'templates#destroy', :via => [:get, :delete]
delete 'templates/bulk_destroy', :to => 'templates#bulk_destroy'

# timelog
match 'easy_time_entries/context_menu', to: 'context_menus#time_entries', as: :easy_time_entries_context_menu, via: [:get, :post]
match 'time_entries/user_spent_time', :to => 'easy_time_entries#user_spent_time', :via => [:get, :post]
match 'time_entries/change_role_activities', :to => 'easy_time_entries#change_role_activities', :via => [:get, :post]
match 'time_entries/change_projects_for_bulk_edit', :to => 'easy_time_entries#change_projects_for_bulk_edit', :via => [:get, :post]
match 'time_entries/change_issues_for_bulk_edit', :to => 'easy_time_entries#change_issues_for_bulk_edit', :via => [:get, :post]
match 'time_entries/change_issues_for_timelog', :to => 'easy_time_entries#change_issues_for_timelog', :via => [:get, :post, :put]
match 'time_entries/bulk_edit', :to => 'easy_time_entries#bulk_edit', :via => [:get, :post]
post 'time_entries/bulk_update', :to => 'easy_time_entries#bulk_update'
post 'time_entries/resolve_easy_lock/:locked', :to => 'easy_time_entries#resolve_easy_lock'
match 'time_entries/:id', :to => 'easy_time_entries#destroy', :via => :delete, :id => /\d+/
match 'time_entries/destroy', :to => 'easy_time_entries#destroy', :via => :delete
resources :time_entries, controller: 'easy_time_entries', except: :destroy do
  get 'report', on: :collection
end

# timelog_calendar
get 'timelog_calendar/calendar', :controller => 'timelog_calendar', :action => 'calendar'

# trackers
match 'trackers/:id/move_issues', :to => 'trackers#move_issues', :via => [:get, :post], :as => 'tracker_move_issues'
match 'trackers/:id/custom_field_mapping', :to => 'trackers#custom_field_mapping', :via => :get, :as => 'tracker_cf_mapping'

# users
match 'users/generate_rss_key', :to => 'users#generate_rss_key', :via => [:get, :post]
match 'users/generate_api_key', :to => 'users#generate_api_key', :via => [:get, :post]
post 'users/save_button_settings', :to => 'users#save_button_settings'
get 'users/find_by_user', :to => 'users#find_by_user'
get 'users/:id/profile', :to => 'users#profile', as: :profile_user
get 'users/bulk_edit', :to => 'users#bulk_edit', as: :bulk_edit_users
delete 'users/bulk_destroy', :to => 'users#bulk_destroy', as: :bulk_destroy_users
match 'users/bulk_update', :to => 'users#bulk_update', as: :bulk_update_users, via: [:put, :post]
get 'users/:id/render_tabs', :to => 'users#render_tabs', :as => 'users_render_tabs'
post 'users/:id/anonymize', to: 'users#anonymize', as: 'anonymize_user'
post 'users/bulk_anonymize', to: 'users#bulk_anonymize', as: :bulk_anonymize_users
match 'users/:id/notify', :to => 'easy_backgrounds#user_notify', :via => [:get, :post]

# versions
match 'versions/toggle_roadmap_trackers', :to => 'versions#toggle_roadmap_trackers', :via => [:get, :post]
post 'versions/bulk_edit', :to => 'versions#bulk_edit'
put 'versions/bulk_update', :to => 'versions#bulk_update'
delete 'versions/bulk_destroy', :to => 'versions#bulk_destroy'

# websocket
#mount EasyExtensions::Websocket::RackApp.new, at: 'websocket', as: 'easy_websocket_rack_app'

# webdav
mount EasyExtensions::Webdav::Handler.new, :at => '/webdav', :as => 'webdav'

# easy_xml_data
get 'easy_xml_data/import_settings', :to => 'easy_xml_data#import_settings', :as => 'easy_xml_data_import_settings'
match 'easy_xml_data/import', :to => 'easy_xml_data#import', :via => [:get, :post], :as => 'easy_xml_data_import'
post 'easy_xml_data/file_preview', to: 'easy_xml_data#file_preview', as: 'easy_xml_data_file_preview'

# easy_xml_easy_pages
match 'easy_xml_easy_pages/import', to: 'easy_xml_easy_pages#import', via: [:get, :post], as: :easy_xml_easy_pages_import
post 'easy_xml_easy_pages/export', to: 'easy_xml_easy_pages#export', as: :easy_xml_easy_pages_export

# easy_xml_easy_page_templates
match 'easy_xml_easy_page_templates/import', to: 'easy_xml_easy_page_templates#import', via: [:get, :post], as: :easy_xml_easy_page_templates_import
post 'easy_xml_easy_page_templates/export', to: 'easy_xml_easy_page_templates#export', as: :easy_xml_easy_page_templates_export

# easy_oauth
get '/easy_external_authentications/:provider/:type/new' => 'easy_external_authentications#new', :type => /(application|user)/, :as => 'easy_external_authentication'
match '/oauth/:provider/callback' => 'easy_external_authentications#create', :via => [:get, :post], :as => 'easy_external_authentication_callback'
delete '/easy_external_authentications/:id/' => 'easy_external_authentications#destroy', :as => 'easy_external_authentication_destroy'

resources :easy_currencies
get 'easy_currencies_exchange_rates', :to => 'easy_currencies_exchange_rates#index'
post 'easy_currencies_exchange_rates', :to => 'easy_currencies_exchange_rates#bulk_update', as: :bulk_update_easy_exchange_rates
post 'settings_easy_currencies_exchange_rates', :to => 'easy_currencies_exchange_rates#update_settings', as: :settings_easy_exchange_rates
get 'settings_easy_currencies_exchange_rates/synchronize_rates', :to => 'easy_currencies_exchange_rates#synchronize_rates', as: :synchronize_exchange_rates

#easy_query_management
resources :easy_default_query_mappings
get 'easy_query_management/:type/edit', to: 'easy_query_management#edit', as: :edit_easy_query_management
put 'easy_query_management/:type/update_default', to: 'easy_query_management#update_default', as: :update_default_easy_query_management
delete 'easy_query_management/:type/destroy_default', to: 'easy_query_management#destroy_default', as: :destroy_default_easy_query_management

# easy_entity_activities
resources :easy_entity_activities # , except: [:show]

# Easy services
match 'easy_services/load_backgrounds', to: 'easy_services#load_backgrounds', as: 'easy_services_load_backgrounds', via: [:get, :post]

# Easy imports
get 'easy_imports/index', to: 'easy_imports#index', as: 'easy_imports'
get 'easy_imports/download_sample_file', to: 'easy_imports#download_sample_file', as: 'easy_imports_download_sample_file'
get 'easy_imports/help/:help', to: 'easy_imports#help', as: 'easy_imports_help'
post 'easy_imports/import', to: 'easy_imports#import', as: 'easy_imports_import'

post 'send_last_internal_error', to: 'easy_errors#send_email', as: 'send_internal_error_email'
post 'download_error', to: 'easy_errors#download_error', as: 'download_error'

if Rails.env.test?
  get 'errors/show', controller: 'easy_errors', action: 'show', as: :show_errors
end

# Easy time entries
resources :easy_time_entries do
  collection do
    get 'personal_attendance_report'
    get 'report'
    post 'bulk_update'
    get 'easy_timesheets'
    match 'user_spent_time', via: [:get, :post]
    match 'change_role_activities', via: [:get, :post]
    match 'change_projects_for_bulk_edit', via: [:get, :post]
    match 'change_issues_for_bulk_edit', via: [:get, :post]
    match 'change_issues_for_timelog', via: [:get, :post]
    match 'bulk_edit', via: [:get, :post]
    post 'resolve_easy_lock'
    get 'report'
    get 'load_users'
    get 'load_assigned_projects'
    get 'load_assigned_issues'
    get 'load_fixed_activities'
    get 'overview'
    get 'overview_layout'
  end
end

delete 'easy_time_entries/destroy', to: 'easy_time_entries#destroy'
get 'easy_time_entries/:time_entry_id', to: 'easy_time_entries#show'

resources :projects do
  resources :easy_time_entries do
    collection do
      get 'report'
    end
  end

  resources :time_entries, controller: :easy_time_entries, only: [:index] do
    get 'report', on: :collection
  end
end

get 'easy_assets/typography'

get 'groups/:id/destroy', as: :destroy_confirmation_group, to: 'groups#destroy_confirmation'
