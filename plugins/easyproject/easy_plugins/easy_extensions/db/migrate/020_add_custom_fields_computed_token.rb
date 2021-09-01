class AddCustomFieldsComputedToken < ActiveRecord::Migration[4.2]
  def self.up
    add_column :custom_fields, :computed_token, :string, { :null => true, :limit => 255 }
  end

  def self.down
    remove_column :custom_fields, :computed_token
  end
end
