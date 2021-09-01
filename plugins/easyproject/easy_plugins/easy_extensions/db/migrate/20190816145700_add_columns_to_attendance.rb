class AddColumnsToAttendance < ActiveRecord::Migration[5.2]

  def up
    EasyAttendance.reset_column_information

    if !column_exists?(:easy_attendances, :easy_external_id)
      add_column :easy_attendances, :easy_external_id, :string, { null: true, limit: 255, index: true }
    end

    if !column_exists?(:easy_attendances, :hours)
      add_column :easy_attendances, :hours, :float, { null: false, default: 0.0 }
    end
  end

  def down
  end

end
