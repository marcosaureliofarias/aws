Redmine::MenuManager.map :admin_dashboard do |menu|
  menu.push :easy_zapier_integration, :easy_zapier_integration_path,
            caption: :'easy_zapier.label_zapier_integration',
            html: { menu_category: 'imports', class: 'icon icon-zapier' },
            if: proc { User.current.admin? && Rys::Feature.active?('easy_zapier') }
end
