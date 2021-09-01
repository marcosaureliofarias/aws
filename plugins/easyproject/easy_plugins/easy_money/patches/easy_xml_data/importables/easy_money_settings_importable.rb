require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneySettingsImportable < Importable
    
    def initialize(data = nil)
      @klass = EasyMoneySettings
      super
    end
    
    def mappable?
      false
    end
    
  end
end
