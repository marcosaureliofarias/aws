class AddDescriptionToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :description, :string, { :null => true, :length => 255 }
  end
end
