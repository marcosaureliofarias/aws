require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class RoleImportable < Importable

    def initialize(data)
      @klass = Role
      super
    end

    def mappable?
      true
    end

    private

    def entities_for_mapping
      roles = []
      @xml.xpath('//easy_xml_data/roles/*').each do |role_xml|
        name  = role_xml.xpath('name').text
        match = Role.where(:name => name).first
        match = Role.create!(name: name) if match.blank? && allowed_to_create_entities?
        roles << { :id => role_xml.xpath('id').text, :name => name, :match => match ? match.id : '' }
      end
      roles
    end

  end
end
