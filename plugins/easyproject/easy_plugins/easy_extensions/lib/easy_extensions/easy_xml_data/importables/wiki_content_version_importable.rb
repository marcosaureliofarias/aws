require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WikiContentVersionImportable < Importable

    def initialize(data)
      @klass = WikiContentVersion
      super
      @belongs_to_associations['wiki_content_id'] = 'wiki_content'
    end

    def mappable?
      false
    end

  end
end