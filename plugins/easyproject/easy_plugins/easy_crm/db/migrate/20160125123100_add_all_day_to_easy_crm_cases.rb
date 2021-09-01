class AddAllDayToEasyCrmCases < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_crm_cases, :all_day, :boolean, :null => false, :default => true
  end

  def down
  end

end
