class AddVersionToKnowledgeStories < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:easy_knowledge_stories, :version)
      add_column :easy_knowledge_stories, :version, :integer, null: false
    end
  end

  def down
  end
end
