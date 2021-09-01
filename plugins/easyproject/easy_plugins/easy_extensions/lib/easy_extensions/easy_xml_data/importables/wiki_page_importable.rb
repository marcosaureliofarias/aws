require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WikiPageImportable < Importable

    def initialize(data)
      @klass = WikiPage
      super
    end

    def mappable?
      false
    end

  end
end