class AddRequiredReadingDateAndReadDateToAssignedStories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_knowledge_assigned_stories, :required_reading_date, :date, { :null => true, :default => nil }
    add_column :easy_knowledge_assigned_stories, :read_date, :date, { :null => true, :default => nil }
  end

  def self.down
    remove_column :easy_knowledge_assigned_stories, :required_reading_date
    remove_column :easy_knowledge_assigned_stories, :read_date
  end
end