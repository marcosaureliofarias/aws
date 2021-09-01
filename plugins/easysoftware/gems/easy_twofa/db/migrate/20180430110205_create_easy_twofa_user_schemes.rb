class CreateEasyTwofaUserSchemes < RedmineExtensions::Migration

  def up
    create_table :easy_twofa_user_schemes do |t|
      t.integer :user_id, null: false
      t.boolean :activated, default: false, null: false
      t.string :scheme_key, null: false
      t.text :settings
      t.timestamps null: false

      t.index :user_id
    end

    add_index :easy_twofa_user_schemes, :user_id, unique: true, name: 'unique_index_easy_twofa_user_schemes_user_id'
  end

  def down
    drop_table :easy_twofa_user_schemes
  end

end
