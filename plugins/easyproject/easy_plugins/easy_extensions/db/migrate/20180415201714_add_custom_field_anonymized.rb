class AddCustomFieldAnonymized < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_fields, :clear_when_anonymize, :boolean, default: false
  end
end
