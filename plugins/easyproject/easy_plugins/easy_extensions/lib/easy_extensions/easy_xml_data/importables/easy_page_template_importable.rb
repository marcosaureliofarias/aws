require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyPageTemplateImportable < Importable
    def initialize(data)
      @klass = EasyPageTemplate
      super
    end

    def mappable?
      true
    end

    def entities_for_mapping
      pages = []
      @xml.xpath('//easy_xml_data/easy-page-templates/*').each do |page_xml|
        template_name = page_xml.xpath('template-name').text
        description   = page_xml.xpath('description').text
        pages << { :id => page_xml.xpath('id').text, template_name: template_name, description: description }
      end
      pages
    end

    private

    def update_attribute(page, name, value, map, xml)
      if name == 'template_name'
        value = map.dig('easy_page_template', 'template_name').presence || value
      elsif name == 'description'
        value = map.dig('easy_page_template', 'description').presence || value
      end
      if name == 'easy_page'
        page.easy_pages_id = EasyPage.find_by(page_name: value).try(:id)
      else
        super
      end
    end

  end
end
