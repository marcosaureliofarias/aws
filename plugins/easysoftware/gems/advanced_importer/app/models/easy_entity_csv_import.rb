require 'csv'
class EasyEntityCsvImport < EasyEntityImport

  attr_reader :csv

  def import_format
    :csv
  end

  def process_preview_file
    @csv ||= CSV.parse_line(@file || get_file)
    @csv
  end

  def import_importer
    set_variables
    super
  end

  def get_csv
    # @xml ||= Nokogiri::XML.parse(@file && @file.read || self.get_file)
    # @xml
  end

  def get_available_entity_types
    %w[EasyContactGroup Project EasyInvoiceLineItem EasyMoneyOtherRevenue EasyCrmCase TimeEntry]
  end

  def import(file)
    set_variables unless @variables_sets
    CSV.new(file, headers: true).each_with_index do |line, index|
      iid = (@xid && line[@xid.source_attribute.to_i].try(:strip))
      iid ||= "#{Date.today.strftime('%Y%m%d')}#{'%05d' % index}" if merge_by != 'id'
      attributes = { 'custom_fields' => [] }
      easy_entity_import_attributes_assignments.each do |att|
        value = att.is_custom? && att.value.presence || (line[att.source_attribute.to_i].try(:strip) || att.default_value)
        attributes = ensure_attribute_value(attributes, att, value.presence)
      end
      entity = prepare_entity(iid)
      entity.project_id = attributes['project_id'] if attributes['project_id']

      entity.send("#{merge_by}=", iid)

      assign_entity_attributes(entity, attributes)

      e = build_imported_entity(iid, entity, line, attributes)
      begin
        is_new_project = e.entity.new_record? && e.entity.is_a?(Project)
        e.entity.save(validate: false)
        e.entity.init_overview_page if is_new_project
        after_save_callback(e.entity, line, attributes)
      rescue StandardError => ex
        raise ex
      end
      @imported_entities[iid] = e
      logger.warn "* Importer CSV [#{entity_class}]: external_id `#{iid}` => #{e.entity.id} (#{e.errors.full_messages.join(', ')})"
    end

    @imported_entities
  end

  # @param [String] external_id often easy_external_id but generally can be everything based on merge_by
  def prepare_entity(external_id)
    entity = entity_class.find_by(merge_by => external_id)
    entity = entity_class.copy_from(template) if entity.nil? && entity_class.respond_to?(:copy_from) && template
    entity ||= entity_class.new

    entity
  end

  def assign_entity_attributes(entity, attributes)
    entity.safe_attributes = attributes
    cols = ((@associations.keys + entity.class.column_names) & attributes.keys)

    priority_cols = %w[project_id tracker_id status_id] & cols
    priority_cols.each do |r|
      if entity.respond_to?(attribute_method = "#{r}=".to_sym)
        entity.send(attribute_method, attributes[r])
      end
    end
  end

  def build_imported_entity(_external_id, new_entity, _csv_line, _current_attributes)
    ImportedEntity.new(new_entity)
  end

  def after_save_callback(entity, _csv_line, _current_attributes)
    return unless template

    entity.copy(template)
    return unless entity.is_a?(Project)

    # New start_date assigment hierarchy:
    # entity.start_date > settings['start_date'] > template.start_date
    new_start_date = entity.start_date || settings['start_date']&.to_date

    if new_start_date && template.start_date && settings['update_dates'] == '1'
      entity.start_date = template.start_date

      day_shift = (new_start_date - template.start_date).to_i
      entity.update_project_entities_dates(day_shift)
    else
      entity.update_column(:easy_start_date, new_start_date)
    end
    entity.update_column(:easy_start_date, new_start_date || template.start_date)

    if settings['match_starting_dates'] == '1'
      entity.match_starting_dates
    end
  end

  def set_variables
    @xid = easy_entity_import_attributes_assignments.detect { |c| c.entity_attribute == merge_by || c.entity_attribute == 'id' }
    @imported_entities = {}
    @associations = entity_type.constantize.reflect_on_all_associations(:belongs_to).map { |r| [r.foreign_key, r.klass] }.to_h rescue {}
    @variables_sets = true
  end

  def ensure_attribute_value(attributes, att, value)
    if value && (r = @associations[att.entity_attribute])
      ensure_association_value(attributes, r, att, value)
    elsif (m = att.entity_attribute.match(/cf_(\d+)/))
      ensure_cf_attribute_value(attributes, m[1], value)
    else
      ensure_default_attribute_value(attributes, att, value)
    end

    attributes
  end

  def logger
    @logger ||= Logger.new(Rails.root.join("log/easy_entity_csv_import-#{id}.log"))
  end

  protected

  # Assign attribute by default
  # If attribute have a format, try convert value to this format
  # @param [Hash] attributes of imported entity
  # @param [EasyEntityImportAttributesAssignment] attribute imported entity attribute of relation, for example: project_id or tracker_id
  # @param [String] value can be ID - assign directly or any other string - in this case try looking in DB by `like`
  def ensure_default_attribute_value(attributes, attribute, value)
    if attribute.format.present?
      value = case entity_class.columns_hash[attribute.entity_attribute].sql_type
              when /time/i
                Time.strptime(value, attribute.format)
              when /date/i
                Date.strptime(value, attribute.format)
              else
                raise ArgumentError, "For #{klass} there is no crystal ball. Please contact Lukas with bribe"
              end
    end
    attributes.store(attribute.entity_attribute, value)

    attributes
  end

  # @param [Hash] attributes of imported entity
  # @param [Integer] cf_id CustomField ID
  # @param [String] value
  def ensure_cf_attribute_value(attributes, cf_id, value)
    @cfs_multiple ||= {}
    @cfs_multiple[cf_id] ||= CustomField.find_by(id: cf_id)
    if @cfs_multiple[cf_id]
      multiple = @cfs_multiple[cf_id].multiple?
      attributes['custom_fields'] << { 'id' => cf_id, 'value' => value && multiple ? value.split('|') : value }
    end

    attributes
  end

  # @param [Hash] attributes of imported entity
  # @param [ActiveRecord] klass of belongs_to relation
  # @param [EasyEntityImportAttributesAssignment] attribute imported entity attribute of relation, for example: project_id or tracker_id
  # @param [String] value can be ID - assign directly or any other string - in this case try looking in DB by `like`
  def ensure_association_value(attributes, klass, attribute, value)
    v = value
    if attribute.allow_find_by_external_id
      v = klass.find_by(easy_external_id: value).try(:id) || attribute.default_value.presence
    elsif value !~ /^\d+$/
      [:named, :like].detect do |find_ass|
        next unless klass.respond_to?(find_ass)

        v = klass.send(find_ass, value).first.try(:id)
      end
    end

    attributes.store(attribute.entity_attribute, v) unless v.nil?

    attributes
  end

  def dependent_fields_for_entity

  end

  class ImportedEntity

    attr_accessor :entity
    attr_reader :errors

    def initialize(entity)
      @entity = entity
      @errors = entity.errors unless entity.valid?
      @errors ||= ActiveModel::Errors.new(entity)
    end

    def id
      @entity.id
    end

    def new_record?
      @entity.new_record?
    end

    def to_model
      @entity
    end

  end

end
# require_dependency 'easy_entity_imports/easy_issue_csv_import'
# require_dependency 'easy_entity_imports/easy_user_csv_import'
