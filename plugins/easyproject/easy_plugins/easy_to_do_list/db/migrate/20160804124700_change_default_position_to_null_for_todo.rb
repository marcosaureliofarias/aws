class ChangeDefaultPositionToNullForTodo < ActiveRecord::Migration[4.2]
  def up
    [:easy_to_do_lists, :easy_to_do_list_items].each do |t|
      change_column t, :position, :integer, { :null => true, :default => nil }
    end
  end

  def down
  end
end
