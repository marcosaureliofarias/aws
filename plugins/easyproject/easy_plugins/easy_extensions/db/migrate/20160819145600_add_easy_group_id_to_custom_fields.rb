class AddEasyGroupIdToCustomFields < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_fields, :easy_group_id, :integer, default: nil
  end
end
