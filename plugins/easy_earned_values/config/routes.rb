# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_earned_values)
  resources :projects, shallow: true do
    resources :easy_earned_values
  end
end
