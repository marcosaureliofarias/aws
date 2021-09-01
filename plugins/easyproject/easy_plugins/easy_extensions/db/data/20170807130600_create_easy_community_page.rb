class CreateEasyCommunityPage < ActiveRecord::Migration[4.2]
  def self.up
    page1 = EasyPage.create!(page_name: 'easy-community', layout_path: 'easy_page_layouts/two_column_header_three_rows_right_sidebar', has_template: false)
  end

  def self.down
    EasyPage.where(page_name: 'easy-community').destroy_all
  end

end
