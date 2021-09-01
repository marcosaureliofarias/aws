class AddEasyCurrencyToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :easy_currency_id, :integer, { :null => true }
  end
end