resources :easy_printable_templates do
  member do
    match 'preview', via: [:get, :post]
    get 'copy_with_pages'
    post 'save_to_document'
    post 'save_to_attachment'
    post 'save_to_pdf'
    post 'generate_docx_from_attachment'
  end
  collection do
    get 'template_chooser'
  end
end

get 'context_menus/easy_printable_templates', :to => 'context_menus#easy_printable_templates'

match 'easy_xml_easy_printable_templates/import', to: 'easy_xml_easy_printable_templates#import', via: [:get, :post], as: :easy_xml_easy_printable_templates_import
post 'easy_xml_easy_printable_templates/export', to: 'easy_xml_easy_printable_templates#export', as: :easy_xml_easy_printable_templates_export