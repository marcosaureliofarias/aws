resources :easy_project_attachments , :only => [:index]
resources :projects do
  resources :easy_project_attachments , :only => [:index]
end
