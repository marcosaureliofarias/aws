class AddEasyResourceDashboardPage < EasyExtensions::EasyDataMigration

  def up
    return unless easy_page_available?

    unless EasyPage.where(page_name: 'easy-resource-dashboard').any?
      EasyPage.create!(page_name: 'easy-resource-dashboard', layout_path: EasyPage::PAGE_LAYOUTS['tchaf'][:path])
    end
  end

  def down
    return unless easy_page_available?

    EasyPage.where(page_name: 'easy-resource-dashboard').destroy_all
  end

  def easy_page_available?
    Redmine::Plugin.installed?(:easy_extensions)
  end

end
