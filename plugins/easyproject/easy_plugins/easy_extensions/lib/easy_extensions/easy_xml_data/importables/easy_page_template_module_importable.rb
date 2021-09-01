require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageTemplateModuleImportable < Importable
    def initialize(data)
      @klass             = EasyPageTemplateModule
      @easy_page_zones   = EasyPageZone.select([:zone_name, :id]).to_a.inject(Hash.new) { |mem, var| mem[var.zone_name] = var; mem }
      @easy_page_modules = EasyPageModule.select([:type, :id]).to_a.inject(Hash.new) { |mem, var| mem[var.type] = var; mem }
      super
    end

    def mappable?
      false
    end

    def entities_for_mapping
      entities = []
      @xml.xpath('//easy_xml_data/easy-page-zone-modules/*').each do |user_xml|
        uuid = user_xml.xpath('uuid').text.strip

        match = EasyPageZoneModule.find_by(uuid: uuid)
        entities << { uuid: uuid, id: uuid, match: match ? match.id : '' }
      end
      entities
    end

    private

    def update_attribute(epm, name, value, map, xml)
      case name
      when 'easy_page_template'
        epm.easy_page_templates_id = map['easy_page_template'][value]
      when 'easy_page_zone'
        epm.easy_page_available_zones_id = EasyPageAvailableZone.where(easy_pages_id: epm.page_definition.id, easy_page_zones_id: @easy_page_zones[value].try(:id)).first.try(:id)
      when 'easy_page_module'
        epm.easy_page_available_modules_id = EasyPageAvailableModule.where(easy_pages_id: epm.page_definition.id, easy_page_modules_id: @easy_page_modules[value].try(:id)).first.try(:id)
      else
        value = map['easy_page_template_tab'][value] if name == 'tab_id' && map['easy_page_template_tab']
        super
      end
    end

    def handle_record_error(record)
      raise StandardError, I18n.t(:xml_data_unavailable_easy_page_module_error) unless record.easy_page_available_modules_id
    end
  end
end
