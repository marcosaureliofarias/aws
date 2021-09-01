class AddIsDefaultToEasyCurrencies < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_currencies, :is_default, :boolean, default: false
  end

  def self.down
    remove_column :easy_currencies, :is_default
  end
end
