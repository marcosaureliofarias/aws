require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class GroupImportable < Importable

    def initialize(data)
      @klass = Group
      super
    end

    def mappable?
      true
    end

    def custom_mapping(map)
      map['principal'] ||= {}
      map['principal'].merge!(map['group'])
    end

    private

    def import_record(xml, map)
      from_id = xml.xpath('id').text
      if map[self.id][from_id].blank?
        super
      else
        to_id = map[self.id][from_id]
        group = Group.find_by(id: to_id)
        return unless group
        user_ids = xml.xpath('users/*').children.map(&:text)
        users    = User.not_in_group(group).where(id: user_ids).to_a
        group.users << users
      end
    end

    def update_attribute(record, name, value, map, xml)
      case name
      when 'easy_lesser_admin_permissions'
        record.easy_lesser_admin_permissions = value.blank? ? [] : Array(value)
      else
        super
      end
    end

    def existing_entities
      klass.all.sort_by(&:name)
    end

    def entities_for_mapping
      groups = []
      @xml.xpath('//easy_xml_data/groups/*').each do |group_xml|
        name  = group_xml.xpath('lastname').text
        match = Group.find_by(lastname: name)
        match = Group.create!(lastname: name) if match.blank? && allowed_to_create_entities?
        groups << { id: group_xml.xpath('id').text, name: name, match: match ? match.id : '' }
      end
      groups
    end

    def after_record_save(group, xml, map)
      from_id                   = xml.xpath('id').text
      map['principal'][from_id] = group.id if from_id.present?
    end

  end
end
