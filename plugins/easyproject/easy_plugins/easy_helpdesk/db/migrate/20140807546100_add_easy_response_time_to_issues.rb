class AddEasyResponseTimeToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_response_date_time, :datetime, {:null => true}
  end

  def self.down
    remove_column :issues, :easy_response_date_time
  end
end