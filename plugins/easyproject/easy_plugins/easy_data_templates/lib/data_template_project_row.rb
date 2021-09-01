require_dependency 'data_template_entity_row_base'

class DataTemplateProjectRow < DataTemplateEntityRowBase

  def prepare_row_for_import(row)
    super
    @entity = Project.new
    fill_entity(@entity)
  end

  def save
    raise ArgumentError, 'Please call prepare_row first.' if @row.nil?

    if @datatemplate.settings['project_template'].blank?
      return @entity.save
    else
      begin
        t = Project.find(@datatemplate.settings['project_template'].to_i)
        fill_entity(t)

        new_project = t.project_from_template('', {:name => t.name})

        return !new_project.new_record?
      rescue
        return false
      end
    end
  end

  def prepare_row_for_export(project)
    data = super(project)
    @datatemplate.assignments.each do |assignment|
      case assignment.entity_attribute_name
      when 'description'
        data[(assignment.file_column_position-1)] = sanitize_clean(project.description)
      when 'id'
        data[(assignment.file_column_position-1)] = sanitize_clean(project.id)
      when 'is_public'
        data[(assignment.file_column_position-1)] = project.is_public == true ? sanitize_clean("A") : sanitize_clean("N")
      when 'name'
        data[(assignment.file_column_position-1)] = sanitize_clean(project.name)
      when 'parent_id'
        data[(assignment.file_column_position-1)] = sanitize_clean(project.parent_id)
      when 'parent_name'
        data[(assignment.file_column_position-1)] = project.parent_id.blank? ? "" : sanitize_clean(project.parent.name)
      when 'trackers_ids'
        data[(assignment.file_column_position-1)] = project.trackers.blank? ? "" : sanitize_clean(project.trackers.pluck(:id).join(","))
      when 'trackers_names'
        data[(assignment.file_column_position-1)] = project.trackers.blank? ? "" : sanitize_clean(project.trackers.pluck(:name).join(","))
      when 'enabled_modules'
        data[(assignment.file_column_position-1)] = project.enabled_modules.blank? ? "" : sanitize_clean(project.enabled_modules.collect{|em| l('project_module_'+em.name)}.join(","))
      else
        data[(assignment.file_column_position-1)] = sanitize_clean(project.custom_value_for(assignment.entity_attribute_name))
      end
    end

    return data
  end

  private

  def fill_entity(project)
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
      when 'description'
        project.description = @row[(assignment.file_column_position-1)].to_s.strip
      when 'is_public'
        project.is_public = @row[(assignment.file_column_position-1)].to_s.strip.casecmp("A").zero? ? true : false
      when 'name'
        project.name = @row[(assignment.file_column_position-1)].to_s.strip
      when 'parent_id'
        #        co s nadrazenyma projektama? jak dam uzivateli vedet, ze nektere neexistuji?
      when 'parent_name'
      when 'trackers_ids'
        my_trackers = Tracker.where(:id => @row[(assignment.file_column_position-1)].split(','))
        project.trackers = my_trackers
      when 'trackers_names'
        my_trackers = Tracker.where(:name => @row[(assignment.file_column_position-1)].to_s.split(','))
        project.trackers = my_trackers
      when 'enabled_modules'
        #        a co ty co nenajdu mezi moduly(at uz chyba v souboru, nebo prekladu), jak dam uzivateli vedet?
        my_available_project_modules = {}
        Redmine::AccessControl.available_project_modules.each{|apm| my_available_project_modules[l('project_module_'+apm.to_s)] = apm.to_s}
        project.enabled_module_names=@row[(assignment.file_column_position-1)].to_s.split(',').select{|x| my_available_project_modules.key?(x)}.collect{|y| my_available_project_modules[y]}
      when 'description'
        project.description = @row[(assignment.file_column_position-1)].to_s.strip
      else
        fill_custom_field_entity(project, assignment.entity_attribute_name.to_i, @row[(assignment.file_column_position-1)])
      end
    end
  end

  def fill_custom_field_entity(project, customfield_id, value)
    cfv = project.custom_field_values.select{|x| x.custom_field_id == customfield_id}.compact.first
    cfv.value = value unless cfv.nil?
  end

  def sanitize_clean(value)
    Sanitize.clean(value.to_s, :output => :html)
  end

end