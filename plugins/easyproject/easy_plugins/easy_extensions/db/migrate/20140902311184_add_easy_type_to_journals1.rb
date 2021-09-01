class AddEasyTypeToJournals1 < ActiveRecord::Migration[4.2]
  def self.up
    add_index :journals, :easy_type
  end

  def self.down
  end

end