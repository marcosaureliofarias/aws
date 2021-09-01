class AddColumnsEasyLastUpdatedByIdAndClosedByIdAndClosedOnToCrmCase < ActiveRecord::Migration[4.2]
  def up
    change_table :easy_crm_cases do |t|
      t.references :easy_last_updated_by, default: nil
      t.references :easy_closed_by, default: nil
      t.datetime :closed_on, default: nil
    end
  end

  def down
    remove_columns :easy_crm_cases, :easy_last_updated_by_id, :easy_closed_by_id, :closed_on
  end
end
