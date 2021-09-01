module EasyCrm

  def self.easy_contacts_custom_fields
    [EasyContacts::CustomFields.email, EasyContacts::CustomFields.telephone, EasyContacts::CustomFields.street,
      EasyContacts::CustomFields.city, EasyContacts::CustomFields.country]
  end

end
