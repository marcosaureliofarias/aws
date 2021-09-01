class CreateEasyFavorites < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_favorites do |t|
      t.references :entity, :polymorphic => true, :null => false
      t.references :user
    end
    add_index :easy_favorites, [:entity_type, :entity_id, :user_id], :name => 'favorite_idx', :unique => true
    add_index :easy_favorites, :user_id
  end

  def down
    drop_table :easy_favorites
  end
end