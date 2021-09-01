class CreateEasyAvatars < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_avatars do |t|
      t.references :entity, :polymorphic => true, :null => false
      t.attachment :image
    end
    add_index :easy_avatars, [:entity_type, :entity_id], :unique => true
    add_index :easy_avatars, :entity_id
  end

  def down
    drop_table :easy_avatars
  end

end
