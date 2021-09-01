Rails.application.routes.draw do
  # Usually definition
  #
  # get 'easy_dagre_d3_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_dagre_d3_issues_2', to: 'issues#index', rys_feature: 'easy_dagre_d3.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_dagre_d3.issue' do
  #   get 'easy_dagre_d3_issues_3', to: 'issues#index'
  # end
end
