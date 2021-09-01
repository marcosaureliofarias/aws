class EasyAdminProjectQuery < EasyProjectQuery

  def initialize_available_filters
    super
    @available_filters.reject! { |key, _| key == 'is_closed' || key == 'is_planned' }

    add_available_filter 'status', caption: :label_status, values: Proc.new { EasyAdminProjectQuery.project_statuses.transform_keys { |k| l("project_status_#{k}") }.to_a }, type: :list, group: default_group_label
  end

  def default_filter
    super.presence || { status: { operator: '=', values: [EasyAdminProjectQuery.project_statuses[:active].to_s] } }
  end

  def default_list_columns
    super.presence || %w[name status description created_on]
  end

  def default_column_groups_ordering
    [
        l(:label_most_used),
        l(:label_filter_group_easy_project_query)
    ]
  end

  def default_group_label
    l(:label_filter_group_easy_project_query)
  end

  def entity_scope
    Project
  end

  def use_visible_condition?
    false
  end

  def entity_easy_query_path(**options)
    options = options.dup
    polymorphic_path([:admin, self.entity], options)
  end

  private

  def self.project_statuses
    { active: Project::STATUS_ACTIVE, archived: Project::STATUS_ARCHIVED, closed: Project::STATUS_CLOSED, planned: Project::STATUS_PLANNED }
  end

end
