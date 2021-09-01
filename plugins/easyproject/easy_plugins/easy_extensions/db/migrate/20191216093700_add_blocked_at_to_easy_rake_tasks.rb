class AddBlockedAtToEasyRakeTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_rake_tasks, :blocked_at, :datetime
  end
end
