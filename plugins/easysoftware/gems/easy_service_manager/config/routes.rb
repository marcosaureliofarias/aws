Rails.application.routes.draw do

  get 'easy_service_manager', to: 'easy_service_manager#index', as: 'easy_service_manager'
  post 'easy_service_manager/verify', to: 'easy_service_manager#verify', as: 'easy_service_manager_verify'
  post 'easy_service_manager/apply', to: 'easy_service_manager#apply', as: 'easy_service_manager_apply'

  scope(constraints: proc { EasyServiceManager.master? }) do
    get 'easy_service_manager_master', to: 'easy_service_manager_master#index', as: 'easy_service_manager_master'
    post 'easy_service_manager_master/generate', to: 'easy_service_manager_master#generate', as: 'easy_service_manager_master_generate'
  end

end
