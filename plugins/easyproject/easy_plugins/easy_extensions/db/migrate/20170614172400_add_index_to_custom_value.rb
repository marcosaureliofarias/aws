class AddIndexToCustomValue < ActiveRecord::Migration[4.2]
  def self.up
    add_index :custom_values, :value, name: :easy_idx_custom_values_value, length: 20
  end

  def self.down
    remove_index :custom_values, name: :easy_idx_custom_values_value
  end
end
