class AddApprovedByToEasyAttendances < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_attendances, :approved_by_id, :integer
    add_column :easy_attendances, :approved_at, :datetime, { :null => true }

    add_index :easy_attendances, :approved_by_id, :name => 'idx_ea_ab_id'
  end

  def self.down
    remove_column :easy_attendances, :approved_by_id
    remove_column :easy_attendances, :approved_at
  end

end