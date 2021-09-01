class EasyEntityNamedCustomAttribute < EasyEntityAttribute

  attr_accessor :custom_field

  def initialize(name, custom_field, options = {})
    super(name, options)
    @custom_field = custom_field
  end

  def value_object(entity, options = {})
    return nil if entity.nil?

    entity = entity.send(assoc) if assoc

    return nil if entity.nil? || !entity.respond_to?(:custom_values)

    if (entity.respond_to?(:project) && @custom_field && @custom_field.visible_by?(entity.project, User.current)) || !entity.respond_to?(:project)
      cv = entity.custom_values.select { |v| v.custom_field_id == @custom_field.id }
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

end
