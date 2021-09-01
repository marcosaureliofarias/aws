class CreateEasyHelpdeskPages < ActiveRecord::Migration[4.2]
  EASY_HELPDESK_PAGE = 'easy-helpdesk-overview'

  def up
    page = EasyPage.create!(:page_name => EASY_HELPDESK_PAGE, :layout_path => 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
  end

  def down
    EasyPage.where(page_name: EASY_HELPDESK_PAGE).destroy_all
  end
end

