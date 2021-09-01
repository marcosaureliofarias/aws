class AddPriceBookToCrmCaseItems < ActiveRecord::Migration[4.2]

  def change
    add_column :easy_crm_case_items, :easy_price_book_item_id, :integer
  end

end
