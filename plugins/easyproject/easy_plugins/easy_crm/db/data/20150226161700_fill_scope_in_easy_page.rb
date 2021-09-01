class FillScopeInEasyPage < ActiveRecord::Migration[4.2]
  def up
    EasyPage.where(:page_name => 'easy-crm-project-overview').update_all(:page_scope => 'project', :has_template => true)
  end

  def down
  end
end
