module EasyContacts
  module CustomFields

    class << self
      def mapping_names
        ['prefix', 'org', 'street', 'postalcode', 'locality' , 'country', 'add_tel', 'add_email']
      end

      def contact_field_ids
        mappings_fields = CustomFieldMapping.where(:format_type => 'vcard').all.group_by(&:name)
        self.mapping_names.map{|name| mappings_fields[name] && mappings_fields[name].first.custom_field_id}.compact
      end

      EasyContact::CF_ATTR_NAMES.each do |att_name|
        define_method(att_name) do
          EasyContactCustomField.find_by(:internal_name => ["easy_contacts_#{att_name}", att_name])
        end

        define_method("#{att_name}_id") do
          Rails.cache.fetch("easy_contact_cf/easy_contacts_#{att_name}_id") do
            self.send(att_name).try(:id) || ''
          end.presence
        end
      end
    end

  end
end
