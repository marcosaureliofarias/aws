require_dependency 'easy_contacts/easy_contacts_custom_fields'
class ImproveEasyContactImporter < ActiveRecord::Migration[4.2]
  def up

    self.field_names.each do |field|
      if EasyContacts::CustomFields.respond_to?("#{field}_id")
        if cf_id = EasyContacts::CustomFields.send("#{field}_id")
          CustomFieldMapping.create(:format_type => 'csv', :custom_field_id => cf_id, :name => field)
        end
      end
    end
  end

  def down
    CustomFieldMapping.where(:format_type => 'csv', :name => self.field_names).destroy_all
  end

  def field_names
    %w(title organization email telephone street city region postal_code country)
  end
end
