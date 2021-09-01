module EasyQuickProjectPlannerHelper

  def quick_planner_edit_tag_for_field(field, project, issue = nil)
    issue ||= Issue.new(project_id: project)
    issue.tracker ||= project.available_trackers.first
    result = ''
    html_id = "easy_quick_project_planner_issue_#{field}#{'-'+issue.id.to_s unless issue.new_record?}"
    field_name = "issue[#{field}]"

    result << case field.to_sym
    when :tracker_id
      select_tag(field_name, (options_from_collection_for_select(project.available_trackers, :id, :name, (issue.tracker && issue.tracker.id)) if project), id: html_id)
    when :assigned_to_id
      select_tag(field_name, newform_assignable_users_options(issue, project), id: html_id)
    when :priority_id
      select_tag(field_name, options_from_collection_for_select(IssuePriority.active, :id, :name, (IssuePriority.default && IssuePriority.default.id)), id: html_id)
    when :fixed_version_id
      select_tag(field_name, version_options_for_select(issue.assignable_versions, issue.fixed_version), include_blank: true, id: html_id)
    when :is_private
      hidden_field_tag(field_name, '0', id: nil) + check_box_tag(field_name, '1', false, id: html_id)
    when :activity_id
      activity_collection = issue.project.activities
      activity_collection << TimeEntryActivity.default if activity_collection.blank? && !TimeEntryActivity.default.nil?
      select_tag(field_name, options_from_collection_for_select(activity_collection,:id, :name, issue.activity_id), include_blank: true, id: html_id)
    when :category_id
      select_tag(field_name, options_from_collection_for_select(project.issue_categories, :id, :name), include_blank: true, id: html_id)
    else
      if field =~ /cf_(\d+)/
        field_name = "issue[custom_field_values][#{$1}]"
        if issue
          custom_field_value = issue.custom_field_values.detect{|val| val.custom_field_id.to_s == $1 }
          custom_field = custom_field_value.custom_field if custom_field_value
        end
        custom_field ||= CustomField.find($1)
        field_name << '[]' if custom_field.multiple?
        custom_field_value ||= CustomFieldValue.new(custom_field: custom_field)
        custom_field.format.edit_tag(self, html_id, field_name, custom_field_value)
      else
        value = issue.send(field) if issue.respond_to?(field)
        text_field_tag(field_name, value, size: (field == 'subject' ? 100 : 10), id: html_id)
      end
    end

    if EasyQuickPlanner::EasyQuickProjectPlanner::DATE_FIELDS.include?(field)
      result << calendar_for(html_id)
    end
    result.html_safe
  end

  def quick_planner_editable_fields(issue)
    @quick_planner_editable_fields ||= %w(estimated_hours due_date)
  end

  def label_for_quick_planner_column_header(field)
    if field =~ /cf_(\d+)/
      CustomField.find($1).translated_name
    else
      l("field_#{field}".sub(/_id$/, ''))
    end
  end

  def attribute_for_field(field)
    @custom_field_cache ||= {}
    if field =~ /cf_(\d+)/
      @custom_field_cache[$1] ||= CustomField.find($1)
      EasyEntityCustomAttribute.new(@custom_field_cache[$1])
    else
      EasyEntityAttribute.new(field.sub(/_id$/,''))
    end
  end

end
