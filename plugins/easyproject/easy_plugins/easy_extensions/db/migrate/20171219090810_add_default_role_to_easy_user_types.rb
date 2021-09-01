class AddDefaultRoleToEasyUserTypes < ActiveRecord::Migration[4.2]
  def change
    add_reference :easy_user_types, :role
  end
end
