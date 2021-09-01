class AddVersionToKnowledgeStory < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_knowledge_story_versions do |t|
      t.column :name, :string, { :null => false, :length => 255 }
      t.column :author_id, :integer, { :null => false }
      t.column :entity_type, :string, { :null => true, :length => 255 }
      t.column :entity_id, :integer, { :null => true }
      t.column :storyviews, :integer, { :null => false, :default => 0 }
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
      t.column :description, :text, { :null => true, :default => nil }
      t.column :version, :integer, :null => false
      t.column :easy_knowledge_story_id, :integer, { :null => false }
    end
    adapter_name = EasyKnowledgeStory.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_knowledge_story_versions, :description, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
    drop_table :easy_knowledge_story_versions
  end
end
