class AddOptionsToAuthSource < ActiveRecord::Migration[4.2]
  def up
    add_column :auth_sources, :easy_options, :text, { :null => true }
  end

  def down
    remove_column :auth_sources, :easy_options
  end
end
