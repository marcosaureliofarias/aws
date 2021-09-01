Rails.application.routes.draw do

  # Usually definition
  #
  # get 'swagger_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'swagger_issues_2', to: 'issues#index', rys_feature: 'easy_swagger.issue'

  # Conditional block definiton
  #
  # rys_feature 'easy_swagger.issue' do
  #   get 'swagger_issues_3', to: 'issues#index'
  # end
  #

  rys_feature 'easy_swagger' do
    get 'easy_swagger', to: 'api_docs#index'
    get 'easy_swagger/docs.:format', to: 'api_docs#index'
  end

end
