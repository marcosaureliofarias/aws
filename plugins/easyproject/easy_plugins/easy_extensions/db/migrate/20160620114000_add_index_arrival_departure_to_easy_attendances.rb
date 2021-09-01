class AddIndexArrivalDepartureToEasyAttendances < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_attendances, [:arrival, :departure], :name => 'idx_ea_ar_de'
  end

  def down
    remove_index :easy_attendances, :name => 'idx_ea_ar_de'
  end
end
