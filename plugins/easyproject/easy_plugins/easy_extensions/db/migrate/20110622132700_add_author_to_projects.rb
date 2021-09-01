class AddAuthorToProjects < ActiveRecord::Migration[4.2]
  def self.up

    add_column :projects, :author_id, :integer, :null => true

  end

  def self.down

    remove_column :projects, :author_id

  end
end
