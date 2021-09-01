class CreateEasyCalendarPage < ActiveRecord::Migration[4.2]
  def up
    page = EasyPage.create!(page_name: 'easy-calendar-module', layout_path: 'easy_page_layouts/two_column_header_first_wider')
  end

  def down
    EasyPage.where(:page_name => 'easy-calendar-module').destroy_all
  end
end
