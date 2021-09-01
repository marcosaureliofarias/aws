class ChangeCustomFieldsType < ActiveRecord::Migration[4.2]
  def self.up
    change_column :custom_fields, :type, :string, { :null => false, :limit => 255 }
  end

  def self.down
  end
end
