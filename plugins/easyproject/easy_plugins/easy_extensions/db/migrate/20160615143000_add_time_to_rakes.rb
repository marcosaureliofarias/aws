class AddTimeToRakes < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_rake_tasks, :last_duration, :integer, { null: false, default: 0 }
    add_column :easy_rake_tasks, :average_duration, :integer, { null: false, default: 0 }
  end
end
