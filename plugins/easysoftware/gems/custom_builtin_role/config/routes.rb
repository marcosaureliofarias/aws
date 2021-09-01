Rails.application.routes.draw do
  # Usually definition
  #
  # get 'custom_builtin_role_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'custom_builtin_role_issues_2', to: 'issues#index', rys_feature: 'custom_builtin_role.issue'

  # Conditional block definiton
  #
  # rys_feature 'custom_builtin_role.issue' do
  #   get 'custom_builtin_role_issues_3', to: 'issues#index'
  # end
end
