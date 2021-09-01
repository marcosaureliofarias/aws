class ChangeDatesInCase < ActiveRecord::Migration[4.2]
  def self.up

    add_column :easy_crm_cases, :next_action, :date, {:null => true}
    rename_column :easy_crm_cases, :due_date, :contract_date

  end

  def self.down
  end

end
