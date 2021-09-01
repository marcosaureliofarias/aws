Rails.application.routes.draw do

  # Usually definition
  #
  # get 'issue_duration_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'issue_duration_issues_2', to: 'issues#index', rys_feature: 'issue_duration.issue'

  # Conditional block definiton
  #
  rys_feature 'issue_duration' do
    get 'calculate_issue_easy_duration', to: 'issue_easy_duration#calculate_easy_duration', as: 'issue_easy_duration_calculate_easy_duration'
    get 'move_date', to: 'issue_easy_duration#move_date', as: 'issue_easy_duration_move_date'
  end

end
