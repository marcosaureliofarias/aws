# encoding: utf-8
class CreateAccountFields < ActiveRecord::Migration[4.2]
  def up
    new_custom_fields = []
    new_custom_fields << {:name => 'Bankovní účet', :attributes =>
      {:field_format => 'string', :is_filter => true, :is_primary => false, :searchable => true, :internal_name => 'easy_contacts_bank_account'}, :export_prefix => 'ACC', :export_name => 'bank_account' }
    new_custom_fields << {:name => 'SWIFT', :attributes =>
      {:field_format => 'string', :is_filter => true, :is_primary => false, :searchable => true, :internal_name => 'easy_contacts_swift'}, :export_prefix => 'ACC', :export_name => 'swift' }
    new_custom_fields << {:name => 'IBAN', :attributes =>
      {:field_format => 'string', :is_filter => true, :is_primary => false, :searchable => true, :internal_name => 'easy_contacts_iban'}, :export_prefix => 'ACC', :export_name => 'iban' }
    new_custom_fields << {:name => 'BIC', :attributes =>
      {:field_format => 'string', :is_filter => true, :is_primary => false, :searchable => true, :internal_name => 'easy_contacts_bic'}, :export_prefix => 'ACC', :export_name => 'bic' }
    new_custom_fields << {:name => 'Variabilní symbol', :attributes =>
      {:field_format => 'string', :is_filter => true, :is_primary => false, :searchable => true, :internal_name => 'easy_contacts_variable_symbol'}, :export_prefix => 'ACC', :export_name => 'variable_symbol' }

    new_custom_fields.each do |source|
      cf = EasyContactCustomField.find_or_initialize_by(name: source[:name])
      cf.contact_type_ids = EasyContactType.pluck(:id)
      if cf.new_record?
        cf.attributes = source[:attributes]
        cf.save!
      end
      CustomFieldMapping.create(:custom_field_id => cf.id, :format_type => 'vcard', :group_name => source[:export_prefix], :name => source[:export_name])
    end
  end

  def down
  end
end
