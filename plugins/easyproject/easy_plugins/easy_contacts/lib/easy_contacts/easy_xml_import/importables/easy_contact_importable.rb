require 'easy_extensions/easy_xml_data/importables/importable'
# require "#{EASY_EXTENSIONS_DIR}/easy_extensions/easy_xml_data/importables/importable"
module EasyXmlData
  class EasyContactImportable < Importable

    def initialize(data)
      @klass = EasyContact
      super
    end

    def mappable?
      true
    end

    private

    # def update_attribute(record, name, value, map, xml)
    #   case name
    #     when 'easy_lesser_admin_permissions'
    #       record.easy_lesser_admin_permissions = value.blank? ? [] : Array(value)
    #     else
    #       super
    #   end
    # end

    def existing_entities
      klass.order(:firstname, :lastname).to_a
    end

    def entities_for_mapping
      entities = []
      @xml.xpath('//easy_xml_data/easy-contacts/*').each do |xml|
        mail = xml.xpath("custom_fields/custom_field[@id='#{EasyContacts::CustomFields.email.id}']").text.strip
        if mail.present?
          cv = CustomValue.where(:customized_type => 'EasyContact', :value => mail).first
          match = cv.customized_id if cv
        end
        entities << {:id => xml.xpath('id').text, :match => match || ''}
      end
      entities
    end

  end
end
