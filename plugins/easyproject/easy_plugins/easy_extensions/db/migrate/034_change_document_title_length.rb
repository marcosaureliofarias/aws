class ChangeDocumentTitleLength < ActiveRecord::Migration[4.2]
  def self.up
    change_column :documents, :title, :string, { :null => false, :limit => 255 }
  end

  def self.down
    # change_column :documents, :title, :string, { :null => false, :limit => 60 } # Is irreversible for current data
  end
end
