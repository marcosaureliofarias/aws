class AddActivatedToEasyCurrency < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_currencies, :activated, :boolean unless column_exists? :easy_currencies, :activated
  end
end
