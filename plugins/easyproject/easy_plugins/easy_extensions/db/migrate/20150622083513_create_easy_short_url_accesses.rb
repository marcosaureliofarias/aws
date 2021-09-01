class CreateEasyShortUrlAccesses < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_short_url_accesses do |t|
      t.references :easy_short_url
      t.references :user, null: true
      t.string :ip, limit: 128
      t.integer :count, null: false, default: 1

      t.timestamps
    end
  end

  def down
    drop_table :easy_short_url_accesses
  end
end
