class AddDefaultColumnsToEasyProjectAttachments < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_project_attachment_query_list_default_columns', :value => ['container_type', 'container_link', 'filename', 'filesize', 'author', 'created_on'])
  end

  def self.down
    EasySetting.where(:name => 'easy_project_attachment_query_list_default_columns').destroy_all
  end
end
