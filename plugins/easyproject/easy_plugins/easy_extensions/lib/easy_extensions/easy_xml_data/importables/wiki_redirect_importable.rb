require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WikiRedirectImportable < Importable

    def initialize(data)
      @klass = WikiRedirect
      super
    end

    def mappable?
      false
    end

  end
end