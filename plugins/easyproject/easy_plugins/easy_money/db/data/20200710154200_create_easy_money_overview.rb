class CreateEasyMoneyOverview < EasyExtensions::EasyDataMigration
  def up
    unless EasyPage.where(page_name: 'easy-money-projects-overview').any?
      page = EasyPage.create!(page_name: 'easy-money-projects-overview', layout_path: 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
      EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('bottom-left')
    end
  end

  def down
    EasyPage.where(page_name: 'easy-money-projects-overview').destroy_all
  end
end