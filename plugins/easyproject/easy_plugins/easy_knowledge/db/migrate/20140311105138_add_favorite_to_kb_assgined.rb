class AddFavoriteToKbAssgined < ActiveRecord::Migration[4.2]
  def up
    change_table :easy_knowledge_assigned_stories do |t|
      t.boolean :is_favorite, :default => false
    end
  end
  def down
    #remove_column :easy_knowledge_assigned_stories, :is_favorite
  end
end
