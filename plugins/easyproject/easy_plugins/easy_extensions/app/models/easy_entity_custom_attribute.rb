class EasyEntityCustomAttribute < EasyEntityAttribute

  attr_reader :custom_field

  FAKE_CUSTOM_VALUE = Struct.new(:value)

  def initialize(custom_field, options = {})
    super("cf_#{custom_field.id}".to_sym, options)
    @custom_field = custom_field
    @numeric      = custom_field.format.numeric?(custom_field)
    @preload      = options[:assoc] ? { options[:assoc] => :custom_values } : :custom_values
  end

  def caption(with_suffixes = false)
    @custom_field.translated_name
  end

  def value_object(entity, options = {})
    return if entity.nil?
    if assoc
      entity           = entity.send(assoc) unless options[:caller]
      options[:caller] = __method__
      proxy            = collection_proxy_for(entity, options)
      return proxy if proxy
    end
    return if entity.nil? || !entity.respond_to?(:custom_values)

    if @custom_field && @custom_field.visible_on?(entity, User.current)
      cv = entity.visible_custom_field_values.select { |v| v.custom_field_id == @custom_field.id }
      cv.size > 1 ? cv.sort { |a, b| a.value.to_s <=> b.value.to_s } : cv.first
    else
      nil
    end
  end

  def value(entity, options = {})
    raw = value_object(entity, options.dup)
    if raw.is_a?(Array)
      raw.map { |r| @custom_field.cast_value(r.value) }
    elsif raw
      @custom_field.cast_value(raw.value)
    else
      nil
    end
  end

  def custom_value_of(entity, options = {})
    return if entity.nil?
    if assoc
      entity           = entity.send(assoc) unless options[:caller]
      options[:caller] = __method__
      proxy            = collection_proxy_for(entity, options)
      return proxy if proxy
    end
    return if entity.nil? || !entity.respond_to?(:custom_value_for)
    entity.custom_value_for(@custom_field)
  end

  def css_classes
    @css_classes ||= [super, @custom_field.field_format.to_s.underscore].reject(&:blank?).join(' ')
  end

  private

  def collection_proxy_for(entity, options)
    if entity.is_a?(ActiveRecord::Associations::CollectionProxy)
      entities = Array(entity)
      entities.map! { |new_entity| send(options[:caller], new_entity, options) }
      FAKE_CUSTOM_VALUE.new(entities.join(', '))
    end
  end

end

module EasyEntityCustomAttributeColumnExtensions

  def self.included(base)
    base.include(EasySumableAttributeColumnExtension)
    base.include(InstanceMethods)
  end

  attr_accessor :sortable, :groupable, :default_order

  def initialize(custom_field, options = {})
    super(custom_field, options)
    self.sortable  = custom_field.order_statement
    self.groupable = options.has_key?(:groupable) ? options[:groupable] : custom_field.group_statement || false
    @inline        = true
    @type          = custom_field.field_format
    if custom_field.summable?
      self.sumable     ||= :both
      self.sumable_sql ||= custom_field.summable_sql
      if assoc && !sumable_options.distinct_columns? && options[:distinct] != false
        self.sumable_options = { distinct_columns: "#{@assoc}_id" }
      end
    end
  end

  def sortable?
    !!sortable
  end

  module InstanceMethods
    def additional_joins(entity_class, type = :sql, uniq = false)
      result = super(entity_class, type).dup

      if assoc
        association = entity_class.reflect_on_all_associations(:belongs_to).detect { |as| as.name == assoc }
        reference   = "#{entity_class.table_name}.#{association.foreign_key}" if association
      end

      join_statement = custom_field.format.join_for_order_statement(custom_field, uniq, reference)

      result << join_statement if join_statement

      result
    end
  end
end
