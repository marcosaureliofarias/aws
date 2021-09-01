class DataTemplateEntityRowBase
  include Redmine::I18n
  
  attr_reader :entity

  def initialize(datatemplate)
    raise ArgumentError, 'The datatemplate has to be a EasyDataTemplate.' unless datatemplate.is_a?(EasyDataTemplate)

    @datatemplate = datatemplate
    @row, @entity, @entity_type = nil, nil, nil
  end
  
  def prepare_row_for_import(row)
    @row = row
  end

  def prepare_row_for_export(entity)
    []
  end

  def valid?
    raise ArgumentError, 'Please call prepare_row first.' if @row.nil?
    return @entity.valid?
  end

  def errors
    raise ArgumentError, 'Please call prepare_row first.' if @row.nil?
    return @entity.errors
  end

  def save
    raise ArgumentError, 'Please call prepare_row first.' if @row.nil?
    return @entity.save
  end

end
