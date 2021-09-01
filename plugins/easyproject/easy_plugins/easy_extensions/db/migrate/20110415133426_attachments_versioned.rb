class AttachmentsVersioned < ActiveRecord::Migration[4.2]
  def self.up
    create_table :attachment_versions do |t|
      t.column :container_id, :integer, :null => false
      t.column :container_type, :string, :limit => 30, :default => "", :null => false
      t.column :filename, :string, :default => "", :null => false
      t.column :disk_filename, :string, :default => "", :null => false
      t.column :filesize, :integer, :default => 0, :null => false
      t.column :content_type, :string, :limit => 120, :default => ""
      t.column :digest, :string, :limit => 40, :default => "", :null => false
      t.column :author_id, :integer, :default => 0, :null => false
      t.column :created_on, :timestamp
      t.column :updated_at, :timestamp
      t.column :attachment_id, :integer, :null => false
      t.column :description, :string, :null => true
      t.column :version, :integer, :null => false
    end
    add_column :attachments, :version, :integer, null: false, default: 0 unless column_exists?(:attachments, :version)
  end

  def self.down
    drop_table :attachment_versions
    remove_column :attachments, :version if column_exists?(:attachments, :version)
  end
end
