Rails.application.routes.draw do
  # Usually definition
  #
  # get 'easy_attendance_info_in_autocomplete_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'easy_attendance_info_in_autocomplete_issues_2', to: 'issues#index', rys_feature: 'easy_attendance_info_in_autocomplete.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_attendance_info_in_autocomplete.issue' do
  #   get 'easy_attendance_info_in_autocomplete_issues_3', to: 'issues#index'
  # end
end
