class FillScopeInEasyPage < ActiveRecord::Migration[4.2]
  def up
    EasyPage.reset_column_information

    EasyPage.where(:page_name => 'my-page').update_all(:page_scope => 'user', :has_template => true)
    EasyPage.where(:page_name => 'project-overview').update_all(:page_scope => 'project', :has_template => true)
  end

  def down
  end
end
