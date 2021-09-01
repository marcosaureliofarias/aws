# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_resource_dashboard)
  get 'easy_resource_dashboard' => 'easy_resource_dashboard#index'

  scope 'easy_resource_dashboard', controller: 'easy_resource_dashboard', as: 'easy_resource_dashboard' do
    get 'index'
    get 'layout'
    get 'load'
  end
end
