class AddIsCustomToPages < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_pages, :is_user_defined, :boolean, { default: false, null: false }
  end
end
