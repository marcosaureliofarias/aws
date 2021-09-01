Rails.application.routes.draw do
  # Usually definition
  #
  # get 'easy_watchers_list_autocomplete_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_watchers_list_autocomplete_issues_2', to: 'issues#index', rys_feature: 'easy_watchers_list_autocomplete.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_watchers_list_autocomplete.issue' do
  #   get 'easy_watchers_list_autocomplete_issues_3', to: 'issues#index'
  # end

  rys_feature 'easy_watchers_list_autocomplete' do
    post 'easy_watchers_list_autocomplete/assignable_watchers'
  end
end
