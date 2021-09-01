class CreateOldPassword < ActiveRecord::Migration[4.2]
  def change
    create_table :old_passwords do |t|
      t.references :user, null: false
      t.string :hashed_password, limit: 40, default: '', null: false
      t.string :salt, limit: 64, default: '', null: false

      t.timestamps null: false
    end
  end
end
