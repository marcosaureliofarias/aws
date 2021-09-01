Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :easy_twofa,
            :setting_easy_twofa_path,
            caption: :'easy_twofa.plugin_name',
            html: { class: 'icon icon-passwd' },
            if: proc { |p| !EasyTwofa.easy_extensions? && User.current.admin? && Rys::Feature.active?('easy_twofa') }
end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_twofa,
#             :easy_twofas_path,
#             caption: :label_easy_twofas,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_twofa,
#             :easy_twofas_path,
#             caption: :label_easy_twofas,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end
