class MakeEasyContactsPrivate < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_contacts, :private, :boolean, :default => false
  end

  def down
    remove_column :easy_contacts, :private
  end
end
