class CreateEasyAttendancesPages < ActiveRecord::Migration[4.2]
  def up
    page = EasyPage.create!(:page_name => 'easy-attendances-overview', :layout_path => 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
  end

  def down
    EasyPage.where(:page_name => 'easy-attendances-overview').destroy_all
  end

end
