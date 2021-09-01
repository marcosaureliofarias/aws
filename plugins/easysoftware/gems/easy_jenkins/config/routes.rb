Rails.application.routes.draw do
  resources :projects do
    member do
      get 'easy_jenkins_settings', to: 'easy_jenkins_settings#project_settings'
    end

    resources :easy_jenkins_settings do
      get :autocomplete_issues, on: :collection
      get :autocomplete_jobs, on: :collection
      get :test_connection, on: :collection
    end

    resources :easy_jenkins_pipelines do
      get :run, on: :collection
      get :history, on: :collection
    end
  end

  resources :easy_jenkins_pipelines do
    post :update_queue, on: :collection
  end
end
