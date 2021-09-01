class DeleteEasyPageModules < ActiveRecord::Migration[4.2]
  def self.up
    EasyPageModule.reset_column_information

    mod1 = EasyPageModule.where(module_name: 'root_project_news').first
    mod1.destroy if mod1

    mod2 = EasyPageModule.where(module_name: 'root_project_tree').first
    mod2.destroy if mod2

    mod3 = EasyPageModule.where(module_name: 'project_sidebar_root_project_info').first
    mod3.destroy if mod3

    mod4 = EasyPageModule.where(module_name: 'project_sidebar_root_project_members').first
    mod4.destroy if mod4

    mod5 = EasyPageModule.where(module_name: 'root_project_issues').first
    mod5.destroy if mod5
  end

  def self.down
  end
end
