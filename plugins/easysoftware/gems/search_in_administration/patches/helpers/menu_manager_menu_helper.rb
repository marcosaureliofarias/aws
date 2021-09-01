Rys::Patcher.add('Redmine::MenuManager::MenuHelper') do

  apply_if_plugins :easy_extensions

  included do
    def administration_search_links
      administration_search = SearchInAdministration::EasyAdministrationSearch.new(self)
      administration_search.fill_settings
      render partial: 'easy_administration_search/administration_search_links', locals: {settings: administration_search.sorted_settings}
    end

    def render_menu_with_search_in_administration(menu_name, project = nil)
      menu = render_menu_without_search_in_administration(menu_name, project)
      menu.prepend(administration_search_links) if Rys::Feature.active?('search_in_administration') && menu_name == :admin_menu
      menu
    end

    alias_method_chain :render_menu, :search_in_administration
  end

end
