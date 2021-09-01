Rails.application.routes.draw do

  # Usually definition
  #
  # get 'ryspec_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'ryspec_issues_2', to: 'issues#index', rys_feature: 'ryspec.issue'

  # Conditional block definiton
  #
  # rys_feature 'ryspec.issue' do
  #   get 'ryspec_issues_3', to: 'issues#index'
  # end

end
