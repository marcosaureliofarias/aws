Rails.application.routes.draw do

  # Usually definition
  #
  # get 'easy_api_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_api_issues_2', to: 'issues#index', rys_feature: 'easy_api.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_api.issue' do
  #   get 'easy_api_issues_3', to: 'issues#index'
  # end

end
