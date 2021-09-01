Rails.application.routes.draw do

  get 'rys_management/:rys_id/edit', to: 'rys_management#edit', as: 'rys_management_edit'
  put 'rys_management/:rys_id/update', to: 'rys_management#update', as: 'rys_management_update'
  post 'rys_management/toggle_feature(/:id)', to: 'rys_management#toggle_feature', as: 'rys_management_toggle_feature'

end
