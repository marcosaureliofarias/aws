class AddDiscountToItems < ActiveRecord::Migration[4.2]
  def up
    add_column(:easy_crm_case_items, :discount, :decimal , null: false, precision: 5, scale: 2, default: 0.0) unless column_exists?(:easy_crm_case_items, :discount)
  end

  def down
    remove_column(:easy_crm_case_items, :discount) if column_exists?(:easy_crm_case_items, :discount)
  end
end
