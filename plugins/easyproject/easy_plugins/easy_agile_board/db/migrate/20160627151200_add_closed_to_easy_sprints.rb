class AddClosedToEasySprints < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_sprints, :closed, :boolean, :default => false
  end

  def down
    remove_column :easy_sprints, :closed
  end
end
