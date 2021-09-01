class EasyEntityImport < ActiveRecord::Base
  include Redmine::SafeAttributes
  has_many :easy_entity_import_attributes_assignments

  validates :type, :name, presence: true
  validates :entity_type, presence: true, if: ->(easy_entity_import) { easy_entity_import.get_available_entity_types.present? }

  attr_reader :file, :project

  store :settings, accessors: [:template_id, :start_date, :update_dates, :match_starting_dates], coder: JSON

  acts_as_attachable

  safe_attributes 'entity_type', 'name', 'settings', 'is_automatic', 'merge_by'

  class << self

    def disabled_sti_class
      EasyDisabledEntityImport
    end

    def disabled?
      false
    end

    def available_import_entities
      available_classes = []
      class_names = AdvancedImporter.config.available_import_entities
      class_names.each do |klass_name|
        if (klass = klass_name.safe_constantize) && !klass.disabled?
          available_classes << klass
        end
      end
      available_classes
    end
  end

  def to_s
    name
  end

  def predefined?
    false
  end

  # get file from URi
  def get_file(uri = nil)
    uri ||= api_url
    return nil if uri.blank?

    EasyUtils::HttpUtils.get_request_body(uri).try(:force_encoding, 'utf-8')
  end

  def get_available_entity_types
    @get_available_entity_types ||= EasyXmlData::Importable.descendants.map { |importable| importable.new({}).klass.name }.sort
  end

  def preview_for_file(preview_file_or_api_url = nil)
    preview_file_or_api_url ||= api_url
    return false if preview_file_or_api_url.blank?

    if preview_file_or_api_url.is_a? ActionDispatch::Http::UploadedFile
      @file = preview_file_or_api_url.tempfile.set_encoding('utf-8')
    elsif preview_file_or_api_url.respond_to?(:diskfile)
      @file = File.open(preview_file_or_api_url.diskfile)
    else
      @file = Tempfile.new('preview_imported_file')
      @file.write(get_file)
      @file.rewind
    end
    process_preview_file if @file.present?
  # ensure
  #   @file.close if @file && !@file.closed?
  end

  def import_content_type
    Redmine::MimeType.of("x.#{import_format}")
  end

  def assign_import_attributes(entity, assign_attributes = {})
    source = assign_attributes.delete(:source_attribute)
    source&.gsub!(/\[\d+\]/, '[*]')
    assignment = easy_entity_import_attributes_assignments.find_by(entity_attribute: entity)
    assignment ||= easy_entity_import_attributes_assignments.build(entity_attribute: entity)
    assignment.attributes = assign_attributes
    assignment.source_attribute = source unless assignment.is_custom?

    Redmine::Hook.call_hook(:easy_entity_import_assign_import_attributes_before_save, easy_entity_import: self, assignment: assignment)
    assignment
  end

  def assign_import_attributes!(entity, assign_attributes = {})
    assignment = assign_import_attributes(entity, assign_attributes)
    assignment.save!
    assignment
  end

  def entity_class
    @entity_class ||= entity_type.safe_constantize
  end

  def required_column_names
    @required_column_names ||= entity_class.validators.select { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }.map(&:attributes).inject([]) { |mem, var| var.each { |v| mem << v.to_s }; mem }
  end

  def assignable_entity_columns
    return @assignable_entity_columns if @assignable_entity_columns.present?
    return AvailableColumns.new unless entity_class

    @assignable_entity_columns = AvailableColumns.new
    @assignable_entity_columns << EasyEntityImportAttribute.new('easy_external_id', required: true)
    @assignable_entity_columns << EasyEntityImportAttribute.new('id')

    entity_class.attribute_names.each do |c|
      next if %w[id easy_external_id].include?(c)

      @assignable_entity_columns << EasyEntityImportAttribute.new(c, required: required_attribute?(required_column_names, c))
    end
    begin
      easy_query = entity_type.downcase.include?('easy') ? "#{entity_type}Query" : "Easy#{entity_type}Query"
      q = easy_query.constantize

      q.new.available_columns.map { |c| @assignable_entity_columns << EasyEntityImportAttribute.new(c.name.to_s, required: required_attribute?(required_column_names, c.name.to_s), title: c.caption, assoc: c.assoc) }

    rescue StandardError => ex
      Rails.logger.debug ex.message
    end

    @assignable_entity_columns
  end

  def native_entity_columns
    @merge_by_entity_columns ||= assignable_entity_columns.select { |c| entity_class.attribute_names.include?(c.name) }
  end

  def primary_assignments
    @primary_assignments ||= easy_entity_import_attributes_assignments.where(entity_attribute: assignable_entity_columns.select { |c| c.assoc.nil? }.map(&:to_s)).to_a
  end

  def assoc_assignments
    @assoc_assignments ||= easy_entity_import_attributes_assignments.where(entity_attribute: assignable_entity_columns.select { |c| !c.assoc.nil? }.map(&:to_s)).to_a
  end

  def required_attribute?(required_column_names, c)
    required_column_names.include?(c) || required_column_names.include?(c.humanize(capitalize: false))
  end

  def template
    return @template if defined?(@template)

    template_id = settings['template_id'].presence
    @template ||= entity_class.find_by(id: template_id) if template_id
    @template
  end

  def import_importer
    output = {}
    if (f = get_file)
      output = import(f)
    else
      attachments.each do |attachment|
        File.open(attachment.diskfile) { |f| output.merge!(import(f)) }
      end
    end
    output
  end

  def attachments_visible?(user = User.current)
    user.admin?
  end

  def attachments_editable?(user = User.current)
    user.admin?
  end

  def attachments_deletable?(user = User.current)
    user.admin?
  end

  # To override
  def import(file)
    raise NotImplementedError
  end

  def import_format
    raise NotImplementedError
  end

  def process_preview_file
    raise NotImplementedError
  end

  def preview_path
    "easy_entity_#{import_format}_preview"
  end

  def form_path
    "easy_entity_#{import_format}_form"
  end

  class EasyEntityImportAttribute
    include Redmine::I18n
    attr_reader :name, :title, :assoc
    attr_writer :required

    def initialize(name, options = {})
      @name = name.to_s
      @caption = options[:caption] || "field_#{name}"
      @title = options[:title]
      @assoc = options[:assoc]
    end

    def caption
      @title || l(@caption, default: @name.humanize)
    end

    def to_s
      [@assoc, @name].compact.join('.')
    end

    def required?
      !!@required
    end

    alias_method :is_required?, :required?

    def is_cf?
      name.match(/^cf_\d+/)[1]
    end

  end

  class AvailableColumns < Hash

    def unwanted_column_names
      %w[lft rgt created_on updated_on created_at updated_at]
    end

    def <<(item)
      unless key?(item.name) || unwanted_column_names.include?(item.name.to_s)
        self[item.name] = item
      end
    end

    def each(&block)
      values.each do |item|
        yield item
      end
    end

    def select(&block)
      values.select &block
    end

  end

end

require_dependency 'easy_entity_xml_import'
require_dependency 'easy_entity_csv_import'
