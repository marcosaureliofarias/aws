Rails.application.routes.draw do
  # Usually definition
  #
  # get 'resource_reports_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'resource_reports_issues_2', to: 'issues#index', rys_feature: 'resource_reports.issue'

  # Conditional block definiton
  #
  # rys_feature 'resource_reports.issue' do
  #   get 'resource_reports_issues_3', to: 'issues#index'
  # end
end
