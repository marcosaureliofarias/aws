class CreateEasyShortUrls < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_short_urls, :force => true do |t|
      t.column 'shortcut', :string, { :limit => 255, :null => false }
      t.column 'source_url', :string, { :limit => 4096, :null => false }
      t.column 'valid_to', :datetime, { :null => true }
      t.column 'entity_type', :string, { :limit => 255, :null => true }
      t.column 'entity_id', :integer, { :null => true }
    end

    add_index :easy_short_urls, [:shortcut], :unique => true
    add_index :easy_short_urls, [:entity_type, :entity_id]
  end

  def self.down
    drop_table :easy_short_urls
  end
end
