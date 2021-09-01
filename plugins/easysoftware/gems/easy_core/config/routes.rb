Rails.application.routes.draw do

  # Usually definition
  #
  # get 'easy_core_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_core_issues_2', to: 'issues#index', rys_feature: 'easy_core.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_core.issue' do
  #   get 'easy_core_issues_3', to: 'issues#index'
  # end

end
