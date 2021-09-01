module EasyQuickPlanner
  class EasyQuickProjectPlanner

    CORE_FIELDS = (Tracker::CORE_FIELDS_ALL.dup + ['activity_id']) - ['project_id', 'description', 'parent_issue_id']

    DATE_FIELDS = %w(start_date due_date)

    def self.available_core_fields
      available_column_names = EasyIssueQuery.new.available_columns.map{|c| c.name.to_s }
      EasyQuickPlanner::EasyQuickProjectPlanner::CORE_FIELDS.select{|f| available_column_names.include?(f.gsub(/_id$/, '')) }
    end

  end
end
