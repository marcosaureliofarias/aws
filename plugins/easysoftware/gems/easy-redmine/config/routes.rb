Rails.application.routes.draw do
  # Usually definition
  #
  # get 'easy/redmine_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy/redmine_issues_2', to: 'issues#index', rys_feature: 'easy.redmine.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy.redmine.issue' do
  #   get 'easy/redmine_issues_3', to: 'issues#index'
  # end
end
