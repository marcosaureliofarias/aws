require 'easy_extensions/easy_xml_data/importables/importable'

module EasyXmlData
  class CustomFieldImportable < Importable

    def initialize(data)
      @klass ||= CustomField
      super
    end

    def mappable?
      true
    end

    private

    def entities_xml
      @xml.xpath("//easy_xml_data/#{klass.name.underscore.pluralize.dasherize}/*")
    end

    def entities_for_mapping
      custom_fields = []
      entities_xml.each do |klass_custom_field_xml|
        internal_name = klass_custom_field_xml.xpath('internal-name').text
        name          = klass_custom_field_xml.xpath('name').text
        unless internal_name.blank?
          match = klass.find_by(internal_name: internal_name)
        end
        if match.blank?
          match = klass.find_by(name: name)
        end
        if match.blank? && allowed_to_create_entities?
          match = klass.create!(internal_name:   internal_name.blank? ? name : internal_name,
                                name:            name,
                                field_format:    klass_custom_field_xml.xpath('field-format').text,
                                possible_values: klass_custom_field_xml.xpath('possible-values').text,
                               )
        end
        custom_fields << { id: klass_custom_field_xml.xpath('id').text, name: name, match: match ? match.id : '' }
      end

      custom_fields
    end

    def update_existing_record(xml, map)
      from_id = xml.xpath('id').text
      to_id   = map[id][from_id]
      record  = klass.find_by(id: to_id)
      return if !record || (record.field_format != 'list' && record.field_format != 'value_tree')

      attr_xml                 = xml.xpath('possible-values').first
      imported_possible_values = attr_xml.children.map(&:text)
      return if imported_possible_values.blank? || (imported_possible_values - record.possible_values).empty?

      result = []
      if record.field_format == 'value_tree'
        hash = {}
        (record.possible_values | imported_possible_values).map { |v| v.split(' > ') }.each do |tokens|
          current_hash = hash
          tokens.each do |token|
            current_hash[token] ||= {}
            current_hash        = current_hash[token]
          end
        end
        convert_hash_to_value_tree(hash, result)
      elsif record.field_format == 'list'
        result = record.possible_values | imported_possible_values
      end

      record.possible_values = result
      record.save
    end

    def convert_hash_to_value_tree(hash, result, parent_token = '')
      hash.each do |k, v|
        current_token = parent_token.dup
        current_token << ' > ' if current_token.present?
        current_token << k
        result << current_token
        convert_hash_to_value_tree(v, result, current_token) if v.any?
      end
    end

  end
end
