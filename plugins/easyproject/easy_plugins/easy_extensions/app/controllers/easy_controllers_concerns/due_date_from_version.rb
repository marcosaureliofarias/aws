module EasyControllersConcerns
  module DueDateFromVersion
    def set_due_date_from_version
      issue_params = params['issue']
      if issue_params && !issue_params['fixed_version_id'].blank? && (current_version = Version.find_by(id: issue_params['fixed_version_id']))
        if issue_params.key?('due_date')
          attrs_due_date = begin
            issue_params['due_date'].to_date;
          rescue;
            nil;
          end
        else
          attrs_due_date = @issue.due_date
        end
        attrs_due_date ||= current_version.due_date
        if current_version.due_date && (current_version.due_date < attrs_due_date)
          attrs_due_date = current_version.due_date
        end

        @issue.due_date = attrs_due_date
      end
    end
  end
end