require_dependency 'data_template_project_row'
require_dependency 'data_template_issue_row'
require_dependency 'data_template_user_row'
require_dependency 'data_template_timeentry_row'

class DataTemplateEntityRowFactory

  def self.create(datatemplate)
    raise ArgumentError, 'The datatemplate has to be a EasyDataTemplate.' unless datatemplate.is_a?(EasyDataTemplate)
    
    case datatemplate.entity_type
      when 'Project'
        return DataTemplateProjectRow.new(datatemplate)
      when 'Issue'
        return DataTemplateIssueRow.new(datatemplate)
      when 'User'
        return DataTemplateUserRow.new(datatemplate)
      when 'TimeEntry'
        return DataTemplateTimeEntryRow.new(datatemplate)
    end
  end

end
