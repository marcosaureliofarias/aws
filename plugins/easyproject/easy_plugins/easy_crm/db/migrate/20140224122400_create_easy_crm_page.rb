class CreateEasyCrmPage < ActiveRecord::Migration[4.2]
  def self.up
    EasyPage.reset_column_information
    page1 = EasyPage.create!(:page_name => 'easy-crm-project-overview', :layout_path => 'easy_page_layouts/two_column_header_three_rows_right_sidebar', :page_scope => 'project', :has_template => true)
    page2 = EasyPage.create!(:page_name => 'easy-crm-overview', :layout_path => 'easy_page_layouts/two_column_header_three_rows_right_sidebar')
  end

  def self.down
    EasyPage.where(:page_name => 'easy-crm-project-overview').destroy_all
    EasyPage.where(:page_name => 'easy-crm-overview').destroy_all
  end

end
