class AddAuthorToDiagram < ActiveRecord::Migration[5.2]
  def change
    add_column :diagrams, :author_id, :integer, index: true
  end
end
