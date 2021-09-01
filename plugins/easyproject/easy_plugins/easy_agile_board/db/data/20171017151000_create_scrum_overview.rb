class CreateScrumOverview < EasyExtensions::EasyDataMigration
  EASY_SPRINT_PAGE = 'easy-sprint-overview'

  def up
    EasyPage.create!(page_name: EASY_SPRINT_PAGE, layout_path: 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
  end

  def down
    EasyPage.where(page_name: EASY_SPRINT_PAGE).destroy_all
  end
end

