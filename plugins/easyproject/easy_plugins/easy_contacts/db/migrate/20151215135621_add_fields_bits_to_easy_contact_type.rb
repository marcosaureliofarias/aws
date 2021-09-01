class AddFieldsBitsToEasyContactType < ActiveRecord::Migration[4.2]
  def change
    add_column EasyContactType.table_name, :fields_bits, :integer, default: 0
  end
end
