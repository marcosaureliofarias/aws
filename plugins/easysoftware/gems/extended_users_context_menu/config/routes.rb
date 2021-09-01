Rails.application.routes.draw do

  # Usually definition
  #
  # get 'extended_users_context_menu_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'extended_users_context_menu_issues_2', to: 'issues#index', rys_feature: 'extended_users_context_menu.issue'

  rys_feature 'extended_users_context_menu' do
    put 'users/add_users_to_group', to: 'users#add_users_to_group', as: :add_users_to_group_users
    put 'users/bulk_calendar_to_user', to: 'users#bulk_calendar_to_user', as: :bulk_calendar_to_user
    put 'users/bulk_generate_passwords', to: 'users#bulk_generate_passwords', as: :bulk_generate_passwords
    put 'users/bulk_next_login_passwords', to: 'users#bulk_next_login_passwords', as: :bulk_next_login_passwords
    put 'users/bulk_update_page_template', to: 'users#bulk_update_page_template', as: :bulk_update_page_template
  end

end
