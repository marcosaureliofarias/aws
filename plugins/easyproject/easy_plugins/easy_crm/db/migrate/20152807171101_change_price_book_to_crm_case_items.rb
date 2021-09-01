class ChangePriceBookToCrmCaseItems < ActiveRecord::Migration[4.2]

  def change
    remove_column :easy_crm_case_items, :easy_price_book_item_id, :integer
    add_column :easy_crm_case_items, :easy_price_book_product_price_id, :integer
  end

end
