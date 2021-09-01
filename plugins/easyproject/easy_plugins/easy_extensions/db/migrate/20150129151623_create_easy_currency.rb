class CreateEasyCurrency < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_currencies do |t|
      t.string :name, null: false
      t.string :iso_code, unique: true, limit: 3, null: false, index: true
      t.integer :digits_after_decimal_separator
      t.string :symbol
    end
  end

  def self.down
    drop_table :easy_currencies
  end
end