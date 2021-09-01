class AddStartEndTimeToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_start_date_time, :datetime
  end
end
