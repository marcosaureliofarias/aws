class AddTimeEntryUnderZero < ActiveRecord::Migration[4.2]
  def up

    add_column :enumerations, :allow_time_entry_zero_hours, :boolean, { :null => false, :default => false }
    add_column :enumerations, :allow_time_entry_negative_hours, :boolean, { :null => false, :default => false }

  end

  def down

    remove_columns :enumerations, :allow_time_entry_zero_hours
    remove_columns :enumerations, :allow_time_entry_negative_hours

  end
end
