Rails.application.routes.draw do

  if Rails.env.development?
    get '/graphql', to: 'easy_graphql#index', as: 'easy_graphql'
    get '/graphql_voyager', to: 'easy_graphql#voyager', as: 'easy_graphql_voyager'

    mount GraphiQL::Rails::Engine, at: '/graphiql', as: 'easy_graphiql', graphql_path: '/graphql'
  end

  post '(/projects/:project_id)/graphql', to: 'easy_graphql#execute', as: 'easy_graphql_execute'

end
