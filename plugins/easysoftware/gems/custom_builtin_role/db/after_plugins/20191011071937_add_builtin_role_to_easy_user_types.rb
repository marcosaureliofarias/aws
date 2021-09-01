class AddBuiltinRoleToEasyUserTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_user_types, :builtin_role_id, :integer
  end
end
