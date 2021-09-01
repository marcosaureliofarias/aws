Rails.application.routes.draw do

  # Usually definition
  #
  # get 'easy_calculoid_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_calculoid_issues_2', to: 'issues#index', rys_feature: 'easy_calculoid.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_calculoid.issue' do
  #   get 'easy_calculoid_issues_3', to: 'issues#index'
  # end

end
