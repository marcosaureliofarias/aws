class AssignUidToContacts < ActiveRecord::Migration[4.2]

  def up
    EasyContact.reset_column_information

    EasyContact.find_each batch_size: 50 do |easy_contact|
      easy_contact.update_column :uid, SecureRandom.uuid
    end
  end

  def down
  end

end
