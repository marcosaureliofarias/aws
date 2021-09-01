Rails.application.routes.draw do

  # Usually definition
  #
  # get 'dependent_list_custom_field_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'dependent_list_custom_field_issues_2', to: 'issues#index', rys_feature: 'dependent_list_custom_field.issue'

  # Conditional block definiton
  #
  # rys_feature 'dependent_list_custom_field.issue' do
  #   get 'dependent_list_custom_field_issues_3', to: 'issues#index'
  # end

end
