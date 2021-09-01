class TestCaseIssueExecutionQuery < EasyQuery

  self.queried_class = TestCaseIssueExecution

  def self.permission_view_entities
    :view_test_case_issue_executions
  end

  def initialize_available_filters
    add_available_filter 'id', name: ::TestCaseIssueExecution.human_attribute_name(:id), type: :integer
    # add_available_filter 'test_case', name: ::TestCaseIssueExecution.human_attribute_name(:test_case), type: :relation
    add_available_filter 'test_case', type: :list_autocomplete, source: 'test_cases_autocomplete', autocomplete_options: { project_id: project_id }, name: TestCaseIssueExecution.human_attribute_name(:test_case)
    add_available_filter 'test_plans', type: :list_autocomplete, source: 'test_plans_autocomplete', autocomplete_options: { project_id: project_id }, name: TestCaseIssueExecution.human_attribute_name(:test_plans)
    add_available_filter 'result_id',
                         name: ::TestCaseIssueExecution.human_attribute_name(:result),
                         type: :list_optional,
                         values: proc { TestCaseIssueExecutionResult.active.sorted.select(:name, :id).map { |p| [p.name, p.id] } }
    add_available_filter 'author_id', type: :list, values: proc { all_users_values(include_me: true) }
    add_available_filter 'issue',
                         :type => :list_autocomplete,
                         source: 'issues_autocomplete',
                         autocomplete_options: { project_id: project_id },
                         :order => 5,
                         :name => EasyEntityActivity.human_attribute_name(:issue)

    # add_available_filter 'created_at', name: ::TestCaseIssueExecution.human_attribute_name(:created_at), type: :date
    # add_available_filter 'updated_at', name: ::TestCaseIssueExecution.human_attribute_name(:updated_at), type: :date
    if Redmine::Plugin.installed? :easy_agile_board
      add_available_filter 'sprint', name: ::TestCaseIssueExecution.human_attribute_name(:sprint), type: :list, values: proc {EasySprint.includes(issues: :test_case_issue_executions).where.not(test_case_issue_executions: {id: nil}).distinct.pluck(:name, :id)}
    end
    add_custom_fields_filters(TestCaseIssueExecutionCustomField)
  end

  def available_columns
    return @available_columns if @available_columns

    add_available_column 'id', title: ::TestCaseIssueExecution.human_attribute_name(:id), caption: ::TestCaseIssueExecution.human_attribute_name(:id), sortable: "#{TestCaseIssueExecution.table_name}.id", groupable: "#{TestCaseIssueExecution.table_name}.id"
    add_available_column 'test_case', title: ::TestCaseIssueExecution.human_attribute_name(:test_case), caption: ::TestCaseIssueExecution.human_attribute_name(:test_case), sortable: "sort_testcase.name", groupable: "#{TestCaseIssueExecution.table_name}.test_case_id", preload: [:test_case]
    add_available_column 'test_case_issue_execution_result', title: ::TestCaseIssueExecution.human_attribute_name(:result), caption: ::TestCaseIssueExecution.human_attribute_name(:result), groupable: "#{TestCaseIssueExecution.table_name}.result_id", sortable: "#{TestCaseIssueExecution.table_name}.result_id"
    add_available_column 'test_plans', title: ::TestCaseIssueExecution.human_attribute_name(:test_plans), caption: ::TestCaseIssueExecution.human_attribute_name(:test_plans), preload: [:test_plans]
    add_available_column 'issue', title: ::TestCaseIssueExecution.human_attribute_name(:issue), caption: ::TestCaseIssueExecution.human_attribute_name(:issue), sortable: "sort_issue.subject", groupable: "#{TestCaseIssueExecution.table_name}.issue_id", preload: [:issue]
    add_available_column 'author', sortable: lambda { User.fields_for_order_statement('sort_author') }, groupable: "#{TestCaseIssueExecution.table_name}.author_id", preload: [:author]
    add_available_column EasyQueryDateColumn.new('created_at', title: ::TestCaseIssueExecution.human_attribute_name(:created_at), caption: ::TestCaseIssueExecution.human_attribute_name(:created_at), sortable: "#{TestCaseIssueExecution.table_name}.created_at")
    add_available_column EasyQueryDateColumn.new('updated_at', title: ::TestCaseIssueExecution.human_attribute_name(:updated_at), caption: ::TestCaseIssueExecution.human_attribute_name(:updated_at), sortable: "#{TestCaseIssueExecution.table_name}.updated_at")
    if Redmine::Plugin.installed? :easy_agile_board
      add_available_column 'easy_sprint', caption: :field_easy_sprint, sortable: "sort_easy_sprint.name", groupable: 'sort_issue.easy_sprint_id', preload: [:easy_sprint]
    end
    @available_columns += TestCaseIssueExecutionCustomField.visible.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def default_columns_names
    super.presence || [:id, :test_case, :test_case_issue_execution_result, :author, :issue].flat_map { |c| [c.to_s, c.to_sym] }
  end

  def default_list_columns
    super.presence || %w(id test_case test_case_issue_execution_result author issue)
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('sort_author')
        joins << "LEFT OUTER JOIN #{User.table_name} sort_author ON sort_author.id = #{self.entity_table_name}.author_id"
      end
      if order_options.include?('sort_testcase')
        joins << "LEFT OUTER JOIN #{TestCase.table_name} sort_testcase ON sort_testcase.id = #{self.entity_table_name}.test_case_id"
      end
      if order_options.include?('sort_issue') || order_options.include?('sort_easy_sprint')
        joins << "LEFT OUTER JOIN #{Issue.table_name} sort_issue ON sort_issue.id = #{self.entity_table_name}.issue_id"
      end
      if order_options.include?('sort_easy_sprint') && Redmine::Plugin.installed?(:easy_agile_board)
        joins << "LEFT OUTER JOIN #{EasySprint.table_name} sort_easy_sprint ON sort_easy_sprint.id = sort_issue.easy_sprint_id"
      end
    end
    joins
  end

  # def default_find_include
  #   # [{issue: :project}]
  #   [:issue]
  # end

  def sql_for_sprint_field(field, operator, value)
    o = operator == '=' ? 'IN' : 'NOT IN'
    values = TestCaseIssueExecution.includes(:easy_sprint).where(easy_sprints: {id: Array(value)}).pluck(:id)
    values.any? && "(#{entity_table_name}.id #{o} (#{values.join(',')}))" || nil
  end

  def sql_for_test_plans_field(field, operator, value)
    o = operator == '=' ? 'IN' : 'NOT IN'
    values = TestCaseIssueExecution.includes(:test_plans).where(test_plans: {id: Array(value)}).pluck(:id)
    values.any? && "(#{entity_table_name}.id #{o} (#{values.join(',')}))" || nil
  end

  def outputs
    super.presence || %w(list)
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def additional_statement
    "test_case_id IN (SELECT id FROM test_cases WHERE project_id=#{project.id})" if project
  end

  def sql_for_issue_field(field, operator, value)
    sql_for_field(field, operator, value, entity_table_name, 'issue_id')
  end

  def sql_for_test_case_field(field, operator, value)
    sql_for_field(field, operator, value, entity_table_name, 'test_case_id')
  end

  # def additional_statement
  #   unless @additional_statement_added
  #     @additional_statement = project_statement unless project_statement.blank?
  #     @additional_statement_added = true
  #   end
  #   @additional_statement
  # end

  # def project_statement
  #   return nil unless project
  #
  #   if try(:force_current_project_filter)
  #     "#{Issue.table_name}.project_id = #{project.id}"
  #   elsif Setting.display_subprojects_issues?
  #     project_clauses = []
  #     ids = [project.id]
  #     if Project.column_names.include?('easy_is_easy_template')
  #       if project.easy_is_easy_template?
  #         ids.concat(project.descendants.templates.pluck(:id))
  #       else
  #         ids.concat(project.descendants.non_templates.pluck(:id))
  #       end
  #     else
  #       ids.concat(project.descendants.pluck(:id))
  #     end
  #     project_clauses << "#{Issue.table_name}.project_id IN (%s)" % ids.join(',')
  #     project_clauses.any? ? project_clauses.join(' AND ') : nil
  #   else
  #     "#{Issue.table_name}.project_id = #{project.id}"
  #   end
  #
  # end

end
