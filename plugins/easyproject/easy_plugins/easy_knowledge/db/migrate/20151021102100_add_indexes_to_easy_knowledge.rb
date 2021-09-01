class AddIndexesToEasyKnowledge < ActiveRecord::Migration[4.2]
  def up
    add_easy_uniq_index :easy_knowledge_story_categories, [:story_id, :category_id], :name => 'idx_story_category'
    add_easy_uniq_index :easy_knowledge_story_references, [:referenced_by, :referenced_to], :name => 'idx_kb_references'
  end

  def down
  end
end