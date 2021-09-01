EasyMonitoring::Engine.routes.draw do

  get 'sys/monitoring(.:format)', to: 'monitoring#monitoring'
  get 'sys/monitoring/sidekiq(.:format)', to: 'monitoring#sidekiq'
  get 'admin/server_resources(.:format)', to: 'monitoring#server_resources'

end
