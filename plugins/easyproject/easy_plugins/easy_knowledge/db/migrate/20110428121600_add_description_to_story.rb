class AddDescriptionToStory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_knowledge_stories, :description, :text, { :null => true, :default => nil }
  end

  def self.down
    remove_column :easy_knowledge_stories, :description
  end
end