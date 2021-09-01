require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageUserTabImportable < Importable
    def initialize(data)
      @klass      = EasyPageUserTab
      @easy_pages = EasyPage.select([:page_name, :id]).to_a.inject(Hash.new) { |mem, var| mem[var.page_name] = var; mem }
      super
    end

    def mappable?
      false
    end

    def entities_for_mapping
      pages = []
      @xml.xpath('//easy_xml_data/easy-page-template-tabs/*').each do |page_xml|
        name = page_xml.xpath('name').text
        pages << { id: page_xml.xpath('id').text, name: name }
      end
      pages
    end

    private

    def update_attribute(page, name, value, map, xml)
      if name == 'page_id'
        return unless value.present?
        value = map['easy_page'][value]
      elsif name == 'easy_page'
        return unless value.present?
        value = @easy_pages[value].try(:id)
        name  = 'page_id'
      elsif name == 'entity_id'
        value = map['project'][value] if value.present?
      end
      super
    end

  end
end