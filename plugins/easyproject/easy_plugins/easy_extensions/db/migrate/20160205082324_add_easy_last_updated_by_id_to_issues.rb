class AddEasyLastUpdatedByIdToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_last_updated_by_id, :integer, default: nil
  end
end
