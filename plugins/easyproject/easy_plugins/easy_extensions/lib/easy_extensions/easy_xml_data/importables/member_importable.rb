require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class MemberImportable < Importable

    def initialize(data)
      @klass = Member
      super
      @belongs_to_many_associations['roles'] = 'role'
    end

    def get_belongs_to_attribute(record, name, value, map, xml)
      if name == 'user_id'
        v = map['principal'][value] if map.has_key?('principal')
        [name, v]
      else
        super
      end
    end

    def mappable?
      false
    end

  end
end
