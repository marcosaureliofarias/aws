# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_wbs)
  resources :projects do
    get 'easy_wbs', to: 'easy_wbs#index', as: 'easy_wbs_index'
    match 'easy_wbs/budget', to: 'easy_wbs#budget', as: 'easy_wbs_budget', via: [:get, :post]
    match 'easy_wbs/budget_overview', to: 'easy_wbs#budget_overview', as: 'easy_wbs_budget_overview', via: [:get, :post]
    match 'easy_wbs/budget_links', to: 'easy_wbs#budget_links', as: 'easy_wbs_budget_links', via: [:get, :post]
  end
end
