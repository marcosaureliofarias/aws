class AddPositionToEasyCrmCaseItems < ActiveRecord::Migration[4.2]
  def change
    add_column(:easy_crm_case_items, :position, :integer, null: true, default: nil)
  end
end
