require_dependency 'data_template_entity_row_base'

class DataTemplateTimeEntryRow < DataTemplateEntityRowBase

  def prepare_row_for_import(row)
    super
    @entity = TimeEntry.new
    fill_entity(@entity)
  end

  def prepare_row_for_export(user)
    data = super(user)
    @datatemplate.assignments.each do |assignment|
      case assignment.entity_attribute_name
      when 'admin'
        data[(assignment.file_column_position-1)] = user.admin == true ? sanitize_clean("A") : sanitize_clean("N")
      when 'firstname'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.firstname)
      when 'lastname'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.lastname)
      when 'login'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.login)
      when 'id'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.id)
      when 'mail'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.mail)
      when 'language'
        data[(assignment.file_column_position-1)] = sanitize_clean(user.language)
      else
        data[(assignment.file_column_position-1)] = sanitize_clean(user.custom_value_for(assignment.entity_attribute_name))
      end
    end

    return data
  end

  private

  def fill_entity(timeentry)
    unless @datatemplate.settings[:encoding] == l(:eady_data_template_encoding)
      ic = Iconv.new(l(:eady_data_template_encoding),@datatemplate.settings['encoding'])
      @datatemplate.assignments.each do |assignment|
        begin
          @row[(assignment.file_column_position-1)] = ic.iconv(@row[(assignment.file_column_position-1)].to_s)
        rescue
          @row[(assignment.file_column_position-1)] = @row[(assignment.file_column_position-1)].to_s
        end
      end
    end

    @datatemplate.assignments.each do |assignment|
      case assignment.entity_attribute_name
      when 'admin'
        user.admin = @row[(assignment.file_column_position-1)].to_s.strip.casecmp("A").zero? ? true : false
      when 'login'
        user.login = @row[(assignment.file_column_position-1)].to_s.strip
      when 'firstname'
        user.firstname = @row[(assignment.file_column_position-1)].to_s.strip
      when 'language'
        user.language = @row[(assignment.file_column_position-1)].to_s.strip
      when 'lastname'
        user.lastname = @row[(assignment.file_column_position-1)].to_s.strip
      when 'mail'
        user.mail = @row[(assignment.file_column_position-1)].to_s.strip
      when 'password'
        user.password = @row[(assignment.file_column_position-1)].to_s.strip
      when 'send_mail'
      else
        fill_custom_field_entity(user, assignment.entity_attribute_name.to_i, @row[(assignment.file_column_position-1)])
      end
    end
  end

  def fill_custom_field_entity(timeentry, customfield_id, value)
    cfv = user.custom_field_values.select{|x| x.custom_field_id == customfield_id}.compact.first
    cfv.value = value.to_s.strip unless cfv.nil?
  end


  def sanitize_clean(value)
    Sanitize.clean(value.to_s, :output => :html)
  end

end
