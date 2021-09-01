##
# A light version of {EasyGanttResource}
#
# It's not a hybrid query !!!
#
# The hybrid query is so complicated that is almost
# imposible to make it "chart supported". That is
# why this query exists.
#
class EasyLightResourceQuery < EasyQuery

  def self.chart_support?
    true
  end

  def self.permission_view_entities
    :view_easy_resources
  end

  def entity
    EasyGanttResource
  end

  def default_list_columns
    super.presence || ['issue', 'hours']
  end

  def filter_groups_ordering
    [
      l('easy_gantt_resources_plugin_name'),
      l('label_most_used'),
      l('label_filter_group_easy_issue_query'),
    ]
  end

  def column_groups_ordering
    filter_groups_ordering
  end

  def initialize_available_filters
    on_filter_group(l('easy_gantt_resources_plugin_name')) do
      add_available_filter 'issue_id', type: :list_autocomplete,
                                       source: 'issue_autocomplete',
                                       source_root: 'entities'

      add_available_filter 'issues.project_id', type: :list_autocomplete,
                                                source: 'visible_projects',
                                                source_root: 'projects',
                                                data_type: :project,
                                                joins: [:issue],
                                                label: :label_project,
                                                klass: Project

      add_principal_autocomplete_filter 'user_id', source_options: { include_groups: '1' }
      add_available_filter 'member_of_group', type: :list_optional,
                                              values: -> { group_values }
      add_available_filter 'hours', type: :float, label: :label_easy_gantt_allocations
      add_available_filter 'original_hours', type: :float, label: :label_easy_gantt_original_allocations
      add_available_filter 'date', type: :date_period, label: :label_date
    end

    on_filter_group(l('label_filter_group_easy_issue_query')) do
       add_available_filter 'author_by_group', type: :list_optional,
                                              values: -> { group_values }

      add_available_filter 'issues.fixed_version_id', type: :list_version,
                                              joins: [issue: :fixed_version],
                                              data_type: :version,
                                              label: :label_fixed_version,
                                              values: -> { version_values }

    end

    add_associations_filters EasyIssueQuery, association_name: :issue,
                                             only: ['start_date', 'due_date', 'done_ratio', 'estimated_hours', 'author_id', 'status_id', 'tracker_id', 'priority_id', 'category_id', /^cf_\d+/, /^project_cf_\d+/]

    add_associations_filters EasyUserQuery, association_name: :user,
                                            only: ['firstname', 'lastname', /^cf_\d+/]

  end

  def initialize_available_columns
    default_group = l('easy_gantt_resources_plugin_name')

    on_column_group(default_group) do
      add_available_column :issue, sortable: 'easy_gantt_resources.issue_id',
                                   groupable: 'easy_gantt_resources.issue_id',
                                   preload: :issue
      add_available_column :user, sortable: 'easy_gantt_resources.user_id',
                                  groupable: 'easy_gantt_resources.user_id',
                                  preload: :user
      add_available_column :hours, sumable: :bottom, caption: :label_easy_gantt_allocations
      add_available_column :original_hours, sumable: :bottom, caption: :label_easy_gantt_original_allocations

      add_available_column EasyQueryDateColumn.new(:date, groupable: true,
                                                          caption: :label_date,
                                                          default_order: 'desc',
                                                          group: default_group)

    end

    add_associated_columns EasyIssueQuery, association_name: :issue, sumable: :bottom, common_sumable_options: { model: 'Issue', distinct_columns: [["#{Issue.table_name}.id", :issue]] }

    add_associated_columns EasyUserQuery, association_name: :user

    # It does not make sence to join hours through an Issue
    disabled_fields = %i[issues.allocated_hours issues.remaining_timeentries]
    @available_columns.reject! { |column| disabled_fields.include?(column.name) }
  end

  def sql_for_member_of_group_field(field, operator, value)
    groups = Group.givable.active

    if operator == '*'
      operator = '='
    elsif operator == '!*'
      operator = '!'
    else
      groups = groups.where(id: value)
    end

    members_of_groups = groups.joins(:users).distinct.pluck('users_users.id')
    sql_for_field('user_id', operator, members_of_groups, 'easy_gantt_resources', 'user_id')
  end

  def sql_for_author_by_group_field(field, operator, value)
    groups = Group.givable.active

    if operator == '*'
      operator = '='
    elsif operator == '!*'
      operator = '!'
    else
      groups = groups.where(id: value)
    end

    members_of_groups = groups.joins(:users).distinct.pluck('users_users.id')
    sql_for_field('author_id', operator, members_of_groups, Issue.table_name, 'author_id')
  end

  def entity_easy_query_path(options)
    easy_light_resources_path(options)
  end

  def version_values
    versions = Version.visible.where(projects: { easy_is_easy_template: false }).joins(:project)
    Version.values_for_select_with_project(versions)
  end

  def group_values
    Group.givable.active.sorted.map {|g| [g.name, g.id.to_s] }
  end
end
