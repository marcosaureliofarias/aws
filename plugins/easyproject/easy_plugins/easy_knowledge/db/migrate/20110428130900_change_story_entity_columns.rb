class ChangeStoryEntityColumns < ActiveRecord::Migration[4.2]
  def self.up
    change_column :easy_knowledge_stories, :entity_type, :string, { :null => true, :length => 255 }
    change_column :easy_knowledge_stories, :entity_id, :integer, { :null => true }
  end

  def self.down
  end
end