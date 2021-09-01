class MoveMappingFieldsToEasyEntityAttributeMapper < ActiveRecord::Migration[4.2]
  def up
    create_map(:firstname, :firstname)
    create_map(:lastname, :lastname)
    m = CustomFieldMapping.where(:format_type => 'vcard').to_a.inject({}){|mem,var| mem[var.name] = var.custom_field_id; mem }
      create_map(:degree, "cf_#{m['prefix']}")
      create_map(:mail, "cf_#{m['add_email']}")
      create_map(:phone, "cf_#{m['add_tel']}")
      create_map(:organization, "cf_#{m['org']}")
      create_map(:city, "cf_#{m['locality']}")
      create_map(:street, "cf_#{m['street']}")
      create_map(:postal_code, "cf_#{m['postalcode']}")
      create_map(:country, "cf_#{m['country']}")
  end

  def create_map(to_attribute, from_attribute)
    begin
      EasyEntityAttributeMap.find_or_create_by(entity_from_type: 'EasyContact', entity_to_type: 'EasyExtensions::Export::EasyVcard', entity_from_attribute: from_attribute, entity_to_attribute: to_attribute)
    rescue StandardError

    end
  end

  def down
    EasyEntityAttributeMap.where(entity_from_type: 'EasyContact').delete_all
  end
end
