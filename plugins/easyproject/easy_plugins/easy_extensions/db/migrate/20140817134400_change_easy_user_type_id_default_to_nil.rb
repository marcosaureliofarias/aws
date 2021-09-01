class ChangeEasyUserTypeIdDefaultToNil < ActiveRecord::Migration[4.2]
  def up
    change_column :users, :easy_user_type_id, :int, :default => nil, :null => true
  end

  def down
    # change_column :users, :easy_user_type_id, :int, :default => 1, :null => false
  end
end
