class UpdateFullnameInEasyContacts < EasyExtensions::EasyDataMigration
  def self.up
    EasyContact.where(fullname: nil).find_each do |contact|
      if contact.fullname != contact.to_s
        contact.update_column(:fullname, contact.to_s)
      end
    end
  end
  
  def self.down
    EasyContact.update_all(fullname: nil)
  end
end
