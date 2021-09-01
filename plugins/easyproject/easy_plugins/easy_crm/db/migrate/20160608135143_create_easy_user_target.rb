class CreateEasyUserTarget < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_user_targets do |t|
      t.references :user
      t.decimal :target, null: false, precision: 30, scale: 2, default: 0.0
      t.string :currency
      t.date :valid_from
      t.date :valid_to

      t.timestamps null: false
    end
    add_column :users, :has_target, :boolean, default: false
  end

  def down
    drop_table :easy_user_targets
    remove_column :users, :has_target
  end

end
