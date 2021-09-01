class EasyWbsEasyIssueQuery < EasyIssueQuery

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

  def easy_query_entity_controller
    'easy_wbs'
  end

  def easy_query_entity_action
    'index'
  end

  def columns
    []
  end

  def groupable_columns
    []
  end

  def sumable_columns
    []
  end

  def project_scope
    super.where.not(status: [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED])
  end

  def entity_easy_query_path(options={})
    if project
      project_easy_wbs_index_path(project, options)
    end
  end

  def query_after_initialize
    super

    self.display_filter_columns_on_index = false
    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index = false
    self.display_filter_settings_on_index = false

    self.display_filter_columns_on_edit = false
    self.display_filter_group_by_on_edit = false
    self.display_filter_sort_on_edit = false
    self.display_filter_settings_on_edit = false

    self.display_show_sum_row = false
    self.display_load_groups_opened = false

    self.export_formats = {}
    self.is_tagged = true if new_record?

    # self.display_filter_fullscreen_button =
    # self.display_save_button =
    # self.display_project_column_if_project_missing =
  end

  def self.chart_support?
    false
  end

end
