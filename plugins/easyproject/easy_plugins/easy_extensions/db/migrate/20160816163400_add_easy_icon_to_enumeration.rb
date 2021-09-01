class AddEasyIconToEnumeration < ActiveRecord::Migration[4.2]
  def change
    add_column :enumerations, :easy_icon, :string
  end
end
