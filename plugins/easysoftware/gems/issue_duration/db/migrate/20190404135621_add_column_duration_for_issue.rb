class AddColumnDurationForIssue < RedmineExtensions::Migration
  def change
    add_column :issues, :easy_duration, :integer, default: nil
  end
end
