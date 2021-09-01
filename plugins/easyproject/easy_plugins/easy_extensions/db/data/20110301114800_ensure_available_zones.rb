class EnsureAvailableZones < ActiveRecord::Migration[4.2]
  def up
    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information


    unless EasyPage.where(page_name: 'my-page').exists?
      EasyPage.create!(page_name: 'my-page', layout_path: 'easy_page_layouts/two_column_header_first_wider')
    end

    unless EasyPage.where(page_name: 'project-overview').exists?
      EasyPage.create!(page_name: 'project-overview', layout_path: 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
    end
  end

  def down
  end
end
