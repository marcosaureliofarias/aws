get 'alert_reports', :to => 'alert_reports#index'
get 'alert_reports.:format', :to => 'alert_reports#index'
get 'alert_reports/:id/archive', :to => 'alert_reports#archive_report'
get 'alert_reports/:id/unarchive', :to => 'alert_reports#unarchive_report'
get 'alert_reports/archive', :to => 'alert_reports#archive'

post 'alerts/context_changed', :to => 'alerts#context_changed'
get 'alerts/rule_changed', :to => 'alerts#rule_changed'
get 'alerts/custom_action', :to => 'alerts#custom_action'
get 'alerts/report', :to => 'alerts#report'

resources :alerts
resources :alert_types
resources :alert_contexts
