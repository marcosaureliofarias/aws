class AddScopeToEasyPages < ActiveRecord::Migration[4.2]
  def up

    add_column :easy_pages, :page_scope, :string, { :null => true, :limit => 255 }
    add_column :easy_pages, :has_template, :boolean, { :null => false, :default => false }

    EasyPage.reset_column_information

  end

  def down
  end
end
