Rails.application.routes.draw do

  # Usually definition
  #
  # get 'project_flags_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'project_flags_issues_2', to: 'issues#index', rys_feature: 'project_flags.issue'

  # Conditional block definiton
  #
  # rys_feature 'project_flags.issue' do
  #   get 'project_flags_issues_3', to: 'issues#index'
  # end

end
