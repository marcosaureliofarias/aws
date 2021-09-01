class ChangeEasyContactCustomFieldFormats < ActiveRecord::Migration[4.2]
  def up
    if c = EasyContactCustomField.where(:internal_name => 'easy_contacts_country').first
      c.update_column(:field_format, 'easy_contact_country_select')
    end

    if c = EasyContactCustomField.where(:internal_name => 'easy_contacts_email').first
      c.update_column(:field_format, 'email')
    end

    if c = EasyContactCustomField.where(:name => 'Titul').first
      c.update_column(:internal_name, 'easy_contacts_title')
      CustomFieldMapping.create(:custom_field_id => c.id, :format_type => 'vcard', :group_name => 'N', :name => 'prefix')
    end
    # Clean up database from unused fields
    CustomFieldMapping.includes(:custom_field).references(:custom_field).where(:custom_fields => {:id => nil}).destroy_all
  end

  def down
  end
end
