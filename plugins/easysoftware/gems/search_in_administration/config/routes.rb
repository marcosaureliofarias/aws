Rails.application.routes.draw do

  # Usually definition
  #
  # get 'search_in_administration_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'search_in_administration_issues_2', to: 'issues#index', rys_feature: 'search_in_administration.issue'

  # Conditional block definiton
  #
  # rys_feature 'search_in_administration.issue' do
  #   get 'search_in_administration_issues_3', to: 'issues#index'
  # end

end
