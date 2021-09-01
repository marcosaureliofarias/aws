class EasyBudgetSheetQuery < EasyTimeEntryBaseQuery

  def query_after_initialize
    super

    self.display_project_column_if_project_missing = false
    self.easy_query_entity_controller = 'budgetsheet'
  end

  def available_filters
    return @easy_budgetsheet_available_filters if @easy_budgetsheet_available_filters

    @easy_budgetsheet_available_filters = super
    @easy_budgetsheet_available_filters['user_id'][:values] = Proc.new { values_for_budgetsheet_user_filter } if @easy_budgetsheet_available_filters['user_id']
    @easy_budgetsheet_available_filters
  end

  def entity_easy_query_path(options)
    budgetsheet_path(options)
  end

  def remove_user_column
    self.column_names = self.columns.map{|column| column.name}.delete_if{|column| column == :user}
  end

  # for uninstall hack
  def entity
    super
  end

  def self.chart_support?
    true
  end

  def self.global_project_context?
    false
  end

  def values_for_budgetsheet_user_filter
    principal_values = []
    principal_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    principal_values.concat(User.easy_budgetsheet_available_users.to_a.map { |u| [ u.to_s, u.id.to_s ] })
    principal_values
  end

end
