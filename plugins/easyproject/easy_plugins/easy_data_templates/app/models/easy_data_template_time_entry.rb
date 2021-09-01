class EasyDataTemplateTimeEntry < EasyDataTemplate

  def all_allowed_columns
    @all_allowed_columns ||= {
      'project' => EasyEntityAttribute.new(:project, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.project'),
      'project_id' => EasyEntityAttribute.new(:project_id, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.project_id'),
      'project_name' => EasyEntityAttribute.new(:'project.name', :caption => :'easy_data_template_entity_attributes_select.TimeEntry.project_name'),
      'issue' => EasyEntityAttribute.new(:issue, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.issue'),
      'issue_id' => EasyEntityAttribute.new(:issue_id, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.issue_id'),
      'issue_subject' => EasyEntityAttribute.new(:'issue.subject', :caption => :'easy_data_template_entity_attributes_select.TimeEntry.issue_subject'),
      'user' => EasyEntityAttribute.new(:user, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.user'),
      'user_id' => EasyEntityAttribute.new(:user_id, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.user_id'),
      'hours' => EasyEntityAttribute.new(:hours, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.hours'),
      'comments' => EasyEntityAttribute.new(:comments, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.comments'),
      'activity' => EasyEntityAttribute.new(:activity, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.activity'),
      'activity_id' => EasyEntityAttribute.new(:activity_id, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.activity_id'),
      'activity_name' => EasyEntityAttribute.new(:'activity.name', :caption => :'easy_data_template_entity_attributes_select.TimeEntry.activity_name'),
      'spent_on' => EasyEntityAttribute.new(:spent_on, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.spent_on'),
      'easy_range_from' => EasyEntityAttribute.new(:easy_range_from, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.easy_range_from'),
      'easy_range_to' => EasyEntityAttribute.new(:easy_range_to, :caption => :'easy_data_template_entity_attributes_select.TimeEntry.easy_range_to')
    }
  end

  def allowed_columns_to_export
    @allowed_columns_to_export ||= ['project_id', 'project_name', 'issue_id', 'issue_subject', 'user_id', 'hours', 'comments', 'activity_id', 'activity_name', 'spent_on', 'easy_range_from', 'easy_range_to']
  end

  def allowed_columns_to_import
    @allowed_columns_to_import ||= ['project', 'issue', 'user', 'hours', 'comments', 'activity', 'spent_on', 'easy_range_from', 'easy_range_to']
  end

  def default_columns_to_export
    @default_columns_to_export ||= ['project_id', 'project_name', 'issue_id', 'issue_subject', 'user_id', 'hours', 'comments', 'activity_id', 'activity_name', 'spent_on', 'easy_range_from', 'easy_range_to']
  end

  def default_columns_to_import
    @default_columns_to_import ||= ['project', 'issue', 'user', 'hours', 'comments', 'activity', 'spent_on', 'easy_range_from', 'easy_range_to']
  end

  def default_settings
    def_set = {}
    if self.template_type == 'import'
      def_set['target_project_id'] = Project.visible.non_templates.sorted.first.id.to_s if Project.visible.non_templates.any?
      def_set['selected_columns'] = self.default_columns_to_import
      def_set
    elsif self.template_type == 'export'
      def_set['source_type'] = 'project'
      def_set['source_project_id'] = Project.visible.non_templates.sorted.first.id.to_s if Project.visible.non_templates.any?
      def_set['selected_columns'] = self.default_columns_to_export
    end
    def_set
  end

  def find_entities(limit = nil)
    if self.settings['source_type'] == 'project'
      p = Project.find(self.settings['source_project_id']) if !self.settings['source_project_id'].blank? && Project.exists?(self.settings['source_project_id'])
      if p
        c = "#{Project.table_name}.id = #{p.id}"
        c << " OR (#{Project.table_name}.lft > #{p.lft} AND #{Project.table_name}.rgt < #{p.rgt})" if Setting.display_subprojects_issues?
        return TimeEntry.joins(:project).where(c).limit(limit) if p
      end
    elsif self.settings['source_type'] == 'easy_time_entry_query'
      q = EasyTimeEntryQuery.find(self.settings['source_query_id']) if !self.settings['source_query_id'].blank? && EasyTimeEntryQuery.exists?(self.settings['source_query_id'])
      return TimeEntry.joins(:project).where(q.statement).limit(limit) if q
    end
  end

  def build_entity_from_csv_row(row_values)
    e = TimeEntry.new
    e.project = row_values['project'][:founded_value]
    e.user = row_values['user'][:founded_value]
    e.issue = row_values['issue'][:founded_value]
    e.hours = row_values['hours'][:founded_value]
    e.comments = row_values['comments'][:founded_value]
    e.activity = row_values['activity'][:founded_value]
    e.spent_on = row_values['spent_on'][:founded_value]
    e.easy_range_from = row_values['easy_range_from'][:founded_value]
    e.easy_range_to = row_values['easy_range_to'][:founded_value]
    e
  end

end
