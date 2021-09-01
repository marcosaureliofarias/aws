class AddEasyTypeToJournals < ActiveRecord::Migration[4.2]
  def self.up
    add_column :journals, :easy_type, :string, { :null => true, :limit => 255 }
  end

  def self.down
    remove_column :journals, :easy_type
  end

end