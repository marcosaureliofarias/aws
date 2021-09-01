class AddTitleToEasyHelpdeskProjectSlas < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_project_slas, :title, :string,  {:null => true}
    EasyHelpdeskProjectSla.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :title
    EasyHelpdeskProjectSla.reset_column_information
  end
end