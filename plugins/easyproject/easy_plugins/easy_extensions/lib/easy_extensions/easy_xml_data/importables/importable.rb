module EasyXmlData
  class Importable

    def initialize(data = nil)
      if data
        @xml = data[:xml]
      end

      @klass ||= self.class.klass

      @belongs_to_associations             = {}
      @belongs_to_polymorphic_associations = {}
      klass.reflect_on_all_associations(:belongs_to).each do |association|
        if association.options[:polymorphic]
          @belongs_to_polymorphic_associations[association.name.to_s + '_id'] = association.options[:foreign_type] || association.foreign_type
        else
          @belongs_to_associations[association.name.to_s + '_id'] = association_id(association)
        end
      end
      @belongs_to_many_associations = {}
      klass.reflect_on_all_associations(:has_and_belongs_to_many).each do |association|
        @belongs_to_many_associations[association.name.to_s] = association_id(association)
      end
      @mapped             = false if mappable?
      @validation_errors  = []
      @processed_entities = {}
    end

    attr_reader :klass, :validation_errors, :processed_entities
    attr_writer :mapped

    # @abstract
    # @return imported class
    def self.klass
      raise NotImplementedError
    end

    def self.xpath
      "//easy_xml_data/#{klass.name.underscore.pluralize.dasherize}/*"
    end

    def import(map, skip_associations)
      @skip_associations = skip_associations
      ep "importing #{id.humanize.pluralize}...", 'r'
      map[id] ||= {}
      @xml.each do |record_xml|
        import_record(record_xml, map)
      end
      ep 'current map:'
      ep map
      ep 'done', 'r'
      return map[id]
    end

    def id
      klass.name.underscore
    end

    def mappable?
      false
    end

    def mapped?
      mappable? && (@mapped || @xml.blank?)
    end

    def mapping_data
      return id, entities_for_mapping, existing_entities
    end

    private

    def import_record(xml, map)
      from_id = xml.xpath('id').text
      if map[self.id][from_id].blank?
        ep "importing #{klass.name}##{from_id}"
        record = create_record(xml, map)
        if record.blank? || record.new_record?
          ep 'import failed'
        else
          ep "imported as #{record.class.name}##{record.id}"
          map[self.id][from_id] = record.id.to_s
        end
        @processed_entities[from_id] = record
        return record
      else
        update_existing_record(xml, map)
      end
    end

    def create_record(xml, map)
      record = klass.new
      unless @skip_associations
        @belongs_to_polymorphic_associations.each do |name, foreign_type|
          type_xml                       = xml.xpath(foreign_type.dasherize)
          @belongs_to_associations[name] = type_xml.text.underscore
        end
      end
      xml.children.each do |attr_xml|
        attr_name = attr_xml.name.underscore
        if updatable_attribute?(attr_name)
          attr_value = attr_xml['type'] == 'array' ? attr_xml.children.map(&:text) : attr_xml.text
          update_attribute(record, attr_name, attr_value, map, attr_xml)
        end
      end

      if !defined?(before_record_save) || before_record_save(record, xml, map)
        begin
          if !validate? && !record.valid?
            handle_record_error(record)
            error_message = "#{record.class.name} #{record.to_s}: "
            error_message << record.errors.full_messages.join(', ')
            ep "validation errors (ignored): #{error_message}", 'rl'
            ep record.pretty_inspect
            ep xml.to_xml
            record.errors.clear
          end
          if record.errors.any? || !record.save(validate: validate?)
            handle_record_error(record)
            error_message = "#{record.class.name} #{record.to_s}: "
            error_message << record.errors.full_messages.join(', ')
            ep "validation errors: #{error_message}", 'rl'
            ep record.pretty_inspect
            ep xml.to_xml
            @validation_errors << error_message
          end
        rescue EasyXmlData::Importer::CancelImportException
          raise
        rescue StandardError => e
          if record.validate
            error_message = "#{record.class.name} #{record.to_s}: #{e.message}"
          else
            error_message = "#{record.class.name} #{record.to_s}: "
            error_message << record.errors.full_messages.join(', ')
          end

          ep "invalid record: #{error_message}"
          @validation_errors << error_message
        end
        if record.persisted?
          after_record_save(record, xml, map) if defined? after_record_save
          restore_original_record_timestamps(record, xml) if keep_original_timestamps?
        end
        return record
      end
    end

    def update_attribute(record, name, value, map, xml)
      if name == 'custom_values'
        set_custom_values(record, map, xml)
        return
      elsif name == 'custom_fields'
        value = xml.xpath('custom_field').each_with_object([]) do |var, mem|
          mem << { 'id' => var['id'], 'value' => var.text.strip }
        end
      elsif @belongs_to_associations.has_key?(name) && !@skip_associations
        name, value = get_belongs_to_attribute(record, name, value, map, xml)
      elsif @belongs_to_many_associations.has_key?(name) && !@skip_associations
        name, value = get_belongs_to_many_attribute(record, name, value, map, xml)
      elsif xml['nil']
        value = nil
      elsif name == 'internal_name'
        value = value.presence
      end
      if xml['type'] == 'yaml'
        if xml['nil'] == 'true'
          value = nil
        else
          value = YAML::load(value)
          value = value.to_unsafe_h if value.is_a? ActionController::Parameters
        end
      elsif xml['type'] == 'array'
        value = value.blank? ? [] : Array(value)
      end

      begin
        record.send("#{name}=", value) if !name.blank? && record.respond_to?("#{name}=")
      rescue ActiveRecord::SerializationTypeMismatch, ActiveRecord::AssociationTypeMismatch
        ep (error = "invalid attribute value #{record.class.name}, attr: #{name}, value: #{value}")
        @validation_errors << error
      end
    end

    def set_custom_values(record, map, xml)
      values = {}
      xml.xpath('./*').each do |custom_value_xml|
        next if custom_value_xml.text?

        custom_field_id                  = custom_value_xml.xpath('custom-field-id').text
        value                            = custom_value_xml.xpath('value').text
        imported_custom_field_id         = map.dig("#{id}_custom_field", custom_field_id)
        values[imported_custom_field_id] = value if imported_custom_field_id.present?
      end
      record.custom_field_values = values
    end

    def get_belongs_to_attribute(record, name, value, map, xml)
      if map.has_key?(@belongs_to_associations[name])
        n = name
        v = map[@belongs_to_associations[name]][value]
        [n, v]
      else
        [name, nil]
      end
    end

    def get_belongs_to_many_attribute(record, name, value, map, xml)
      if map.has_key?(@belongs_to_many_associations[name])
        value = []
        type  = @belongs_to_many_associations[name]
        xml.children.each do |other_xml|
          other_id = other_xml.text
          if other_id && map[type][other_id]
            value << map[type][other_id]
          end
        end
        ["#{type}_ids", value]
      else
        [nil, nil]
      end
    end

    def updatable_attribute?(attr_name)
      !['id', 'lft', 'rgt', 'parent_id'].include?(attr_name)
    end

    def entities_for_mapping
      raise StandardError, 'this method should be overridden'
    end

    def existing_entities
      klass.all
    end

    def association_id(association)
      cn = association.class_name.underscore
      cn == 'principal' ? 'user' : cn
    end

    def restore_original_record_timestamps(record, xml)
      ep "trying to detect original timestamps"

      query = []

      if xml.xpath('created-on').present? && record.respond_to?(:created_on=)
        created_on = Time.parse(xml.xpath('created-on').text)
        query << record.class.sanitize_sql_for_assignment([record.class.table_name + '.created_on = ?', created_on])
        ep "creating date restored to " + created_on.to_s
      end

      if xml.xpath('updated-on').present? && record.respond_to?(:updated_on=)
        updated_on = Time.parse(xml.xpath('updated-on').text)
        query << record.class.sanitize_sql_for_assignment([record.class.table_name + '.updated_on = ?', updated_on])
        ep "updating date restored to " + updated_on.to_s
      end

      if query.any?
        ActiveRecord::Base.connection.execute("UPDATE #{record.class.table_name} SET " + query.join(', ') + " WHERE #{record.class.table_name}.id = " + record.id.to_i.to_s)
      end
    end

    def handle_record_error(record)

    end

    def update_existing_record(xml, map)

    end

    def validate?
      # any default value here is a danger
      # if we do validation, we risk to lose data just because of different settings of the source and the target
      # if we skip validation, we risk to pass incorrect data because of possible bugs in the exporter / importer code
      if ENV.has_key? 'EASY_IMPORTER_SKIP_VALIDATION'
        !ENV['EASY_IMPORTER_SKIP_VALIDATION'].to_boolean
      else
        true
      end
    end

    def allowed_to_create_entities?
      ENV['EASY_IMPORTER_CREATE_IF_NOT_EXISTS'].to_boolean
    end

    def keep_original_timestamps?
      ENV['EASY_IMPORTER_KEEP_ORIGINAL_TIMESTAMPS'].to_boolean
    end

  end
end
