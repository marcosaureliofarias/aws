Rails.application.routes.draw do

  # Usually definition
  #
  # get 'show_last_comments_on_issue_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'show_last_comments_on_issue_issues_2', to: 'issues#index', rys_feature: 'show_last_comments_on_issue.issue'

  # Conditional block definiton
  #
  # rys_feature 'show_last_comments_on_issue.issue' do
  #   get 'show_last_comments_on_issue_issues_3', to: 'issues#index'
  # end

end
