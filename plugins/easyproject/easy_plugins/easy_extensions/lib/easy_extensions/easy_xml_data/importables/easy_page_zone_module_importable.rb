require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageZoneModuleImportable < Importable
    def initialize(data)
      @klass             = EasyPageZoneModule
      @easy_pages        = EasyPage.select([:page_name, :id]).to_a.inject(Hash.new) { |mem, var| mem[var.page_name] = var; mem }
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

        match = EasyPageZoneModule.find_by(:uuid => uuid)
        entities << { :uuid => uuid, :id => uuid, :match => match ? match.id : '' }
      end
      entities
    end

    private

    def update_attribute(epm, name, value, map, xml)
      case name
      when 'entity_id'
        epm.entity_id = value.presence && map['project'].presence && map['project'][value]
      when 'easy_page'
        epm.easy_pages_id = map['easy_page'].present? ? map['easy_page'][value] : @easy_pages[value].try(:id)
      when 'easy_page_zone'
        epm.easy_page_available_zones_id = EasyPageAvailableZone.where(easy_pages_id: epm.easy_pages_id, easy_page_zones_id: @easy_page_zones[value].try(:id)).first.try(:id)
      when 'easy_page_module'
        epm.easy_page_available_modules_id = EasyPageAvailableModule.where(easy_pages_id: epm.easy_pages_id, easy_page_modules_id: @easy_page_modules[value].try(:id)).first.try(:id)
      when 'tab_id'
        epm.tab_id = map['easy_page_user_tab'][value] if map['easy_page_user_tab']
      else
        value = map['easy_page_user_tab'][value] if name == 'tab_id' && map['easy_page_user_tab']
        super
      end
    end

    def handle_record_error(record)
      raise StandardError, I18n.t(:xml_data_unavailable_easy_page_module_error) unless record.easy_page_available_modules_id
    end
  end
end
