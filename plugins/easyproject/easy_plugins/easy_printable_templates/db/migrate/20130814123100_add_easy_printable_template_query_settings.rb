class AddEasyPrintableTemplateQuerySettings < ActiveRecord::Migration[4.2]

  def self.up
    EasySetting.create(:name => 'easy_printable_template_query_list_default_columns', :value => ['project', 'name', 'author'])
  end

  def self.down
    EasySetting.where(:name => 'easy_printable_template_query_list_default_columns').destroy_all
  end
end