class AddDestroyAtToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :destroy_at, :datetime, null: true
  end
end
