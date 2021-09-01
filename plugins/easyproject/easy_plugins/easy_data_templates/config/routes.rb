resources :easy_data_templates do
  member do
    match :import, via: [:get, :post]
    match :export, via: [:get, :post]
    match :import_data, via: [:get, :post]
    match :export_data, via: [:get, :post]
    match :update_settings, via: [:get, :post]
  end
end

#match 'easy_data_templates_ms_project/:id/export.:format', :controller => 'easy_data_templates_ms_project', :action => 'export'
#match 'easy_data_templates_ms_project/:id/import', :controller => 'easy_data_templates_ms_project', :action => 'import'
get 'easy_data_template_ms_projects/:id/import_settings', :controller => 'easy_data_template_ms_projects', :action => 'import_settings'
post 'easy_data_template_ms_projects/:id/import_settings', :controller => 'easy_data_template_ms_projects', :action => 'import_data'

get 'easy_data_templates_import/new', :controller => 'easy_data_templates_import', :action => 'new'
post 'easy_data_templates_import/create', :controller => 'easy_data_templates_import', :action => 'create'
get 'easy_data_templates_import/:id/edit', :controller => 'easy_data_templates_import', :action => 'edit'
put 'easy_data_templates_import/:id', :controller => 'easy_data_templates_import', :action => 'update'
match 'easy_data_templates_import/:id/import_settings' => 'easy_data_templates_import#import_settings', via: [:get, :post]
post 'easy_data_templates_import/:id/import', :controller => 'easy_data_templates_import', :action => 'import'

get 'easy_data_templates_export/new', :controller => 'easy_data_templates_export', :action => 'new'
post 'easy_data_templates_export/create', :controller => 'easy_data_templates_export', :action => 'create'
get 'easy_data_templates_export/:id/edit', :controller => 'easy_data_templates_export', :action => 'edit'
put 'easy_data_templates_export/:id', :controller => 'easy_data_templates_export', :action => 'update'
match 'easy_data_templates_export/:id/export_settings', :controller => 'easy_data_templates_export', :action => 'export_settings', via: [:get, :post]
post 'easy_data_templates_export/:id/export', :controller => 'easy_data_templates_export', :action => 'export'

get 'easy_xml_data/export_settings', :to => 'easy_xml_data#export_settings'
post 'easy_xml_data/export', :to => 'easy_xml_data#export', :as => 'easy_xml_data_export'

resources :easy_data_template_ms_projects

