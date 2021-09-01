require_dependency 'easy_xml_data/exporter'

ActiveSupport.on_load(:easyproject, yield: true) do
  EasyExtensions::ActionProposer.add({ controller: 'easy_data_templates', action: 'index' })
  EasyExtensions::ActionProposer.add({ controller: 'easy_xml_data', action: 'export_settings' })

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_xml_data_export, {controller: 'easy_xml_data', action: 'export_settings'}, caption: :label_xml_data_export, if: proc {|_| User.current.admin? }, html: {class: 'icon icon-export'}, after: :easy_xml_data_import
    menu.push :easy_data_templates, {controller: 'easy_data_templates', action: 'index'}, caption: :label_easy_data_templates, if: proc {|_| User.current.admin? }, html: {class: 'icon icon-copy'}, before: :settings
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_data_templates, {controller: 'easy_data_templates', action: 'index'}, caption: :label_easy_data_templates, if: proc {|_| User.current.admin? }, html: {menu_category: 'settings', class: 'icon icon-copy'}, before: :settings
  end
end
