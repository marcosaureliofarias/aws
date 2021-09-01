class AddIssueStatusesDescription < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_statuses, :description, :text, :after => :name
  end
end
