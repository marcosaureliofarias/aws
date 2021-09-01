class AddTreeOnContact < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_contacts, :parent_id, :integer, default: nil
    add_column :easy_contacts, :root_id, :integer, default: nil
    add_column :easy_contacts, :lft, :integer, default: nil
    add_column :easy_contacts, :rgt, :integer, default: nil

    EasyContact.update_all("parent_id = NULL, root_id = id, lft = 1, rgt = 2")
  end
  def down
    remove_column :easy_contacts, :parent_id
    remove_column :easy_contacts, :root_id
    remove_column :easy_contacts, :lft
    remove_column :easy_contacts, :rgt
  end

end
