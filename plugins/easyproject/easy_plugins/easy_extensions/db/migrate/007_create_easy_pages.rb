class CreateEasyPages < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_pages do |t|
      t.column :page_name, :string, { :null => false, :length => 255 }
      t.column :layout_path, :string, { :null => false, :length => 255 }
    end
  end

  def self.down
    drop_table :easy_pages
  end
end
