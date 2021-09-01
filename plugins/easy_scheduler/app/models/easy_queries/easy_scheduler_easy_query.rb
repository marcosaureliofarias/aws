class EasySchedulerEasyQuery < EasyIssueQuery

  def entity_easy_query_path(options = {})
    if options[:project]
      project_path(options[:project])
    else
      home_path
    end
  end

  def self.permission_view_entities
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

  def self.chart_support?
    false
  end

  def table_support?
    false
  end

  def display_entity_count?
    false
  end

  def display_show_avatars?
    false
  end

  def groupable_columns
    []
  end

  def sumable_columns
    []
  end

  def default_filter
    super.presence || {
      assigned_to_id: { operator: '=', values: ['me'] },
      status_id: { operator: 'o', values: [''] }
    }
  end

  def default_sort_criteria
    super.presence || [['priority', 'desc']]
  end

  def default_group_label
    l("label_filter_group_#{EasyIssueQuery.name.underscore.tr('/', '.')}")
  end

  def to_params(options = {})
    easy_query_params = super

    if settings['selected_principal_ids']
      easy_query_params[:settings][:selected_principal_ids] = settings['selected_principal_ids']
    end

    easy_query_params
  end

  def query_after_initialize
    super

    self.display_filter_columns_on_index = false
    self.display_filter_columns_on_edit = false
    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index = false
    self.display_filter_settings_on_index = false

    self.display_filter_group_by_on_edit = false
    self.display_filter_settings_on_edit = false

    self.display_show_sum_row = false
    self.display_load_groups_opened = false
    self.display_outputs_select_on_index = false
    self.display_outputs_select_on_edit = false

    self.export_formats = {}
    self.is_tagged = true if new_record?
    self.display_filter_fullscreen_button = false
    self.easy_query_entity_controller = 'easy_scheduler'
  end

  def self.translated_name
    EasyIssueQuery.translated_name
  end
end
