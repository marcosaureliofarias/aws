class CreateEasyProjectTemplateQuerySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_project_template_query_list_default_columns', :value => ['name', 'description'])
  end

  def self.down
    EasySetting.where(:name => 'easy_project_template_query_list_default_columns').destroy_all
  end
end
