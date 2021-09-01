class RenameEasyUserTypeToEasyUserTypeId < ActiveRecord::Migration[4.2]

  def up
    rename_column :users, :easy_user_type, :easy_user_type_id
    User.reset_column_information
  end

  def down
    rename_column :users, :easy_user_type_id, :easy_user_type
    User.reset_column_information
  end

end
