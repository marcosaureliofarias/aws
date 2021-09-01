require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WikiContentImportable < Importable

    def initialize(data)
      @klass = WikiContent
      super
    end

    def mappable?
      false
    end

    def create_record(xml, map)
      wiki_content = super
      unless wiki_content.new_record?
        wiki_content.versions.each(&:delete)
        wiki_content.update_column(:version, xml.xpath('version').text)
      end
      wiki_content
    end

  end
end