class EnsureStatisticsPageAvailable < ActiveRecord::Migration[4.2]
  def up
    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information

    unless EasyPage.where(page_name: 'statistics-test-cases').exists?
      EasyPage.create!(page_name: 'statistics-test-cases', layout_path: 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
    end
  end

  def down
    page = EasyPage.find_by(page_name: 'statistics-test-cases')
    if page.present?
      page.destroy
    end
  end
end
