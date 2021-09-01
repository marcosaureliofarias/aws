class EasyMoneyProjectCacheQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_money
  end

  def query_after_initialize
    super
    self.easy_query_entity_controller              = 'easy_money_project_caches'
    self.display_project_column_if_project_missing = false
  end

  def project_module
    :easy_money
  end

  def additional_statement
    unless @additional_statement_added
      sql                         = project_statement
      @additional_statement       = sql unless sql.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def initialize_available_filters
    on_filter_group(l(:label_filter_group_easy_money_project_cache_query)) do
      unless project
        add_available_filter 'project_id', { type: :list_autocomplete, order: 1, source: 'visible_projects', source_root: 'projects', data_type: :project }
        add_available_filter 'parent_id', { type: :list_optional, order: 2, values: proc { all_projects_parents_values }, data_type: :project }
        add_available_filter 'main_project', { type: :list_optional, order: 3, values: proc { all_main_projects_values }, data_type: :project }
      end

      add_available_filter 'average_hourly_rate_price_1', { type: :float, order: 42 }
      add_available_filter 'average_hourly_rate_price_2', { type: :float, order: 43 }
      add_available_filter 'is_project_closed', { type: :boolean, order: 4, name: l(:field_is_project_closed) }
      add_principal_autocomplete_filter 'author_id', { klass: User, order: 44 }
      add_available_filter 'cost_ratio', { type: :float, order: 45 }
      add_available_filter 'sum_of_expected_hours', { type: :float, order: 10 }
      add_available_filter 'sum_of_estimated_hours', { type: :float, order: 22, name: l(:field_estimated_hours) }
      add_available_filter 'sum_of_timeentries', { type: :float, order: 23 }
    end

    on_filter_group(l(:label_filter_group_easy_money_project_cache_expenses)) do
      add_available_filter 'sum_of_expected_payroll_expenses', { type: :float, order: 11 } if User.current.allowed_to_globally?(:easy_money_show_expected_payroll_expense, {})
      add_available_filter 'sum_of_expected_expenses_price_1', { type: :float, order: 12 } if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      add_available_filter 'sum_of_expected_expenses_price_2', { type: :float, order: 16 } if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      add_available_filter 'sum_of_all_expected_expenses_price_1', { type: :float, order: 24 } if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      add_available_filter 'sum_of_all_expected_expenses_price_2', { type: :float, order: 27 } if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})

      if User.current.allowed_to_globally?(:easy_money_show_time_entry_expenses, {})
        add_available_filter 'sum_of_time_entries_expenses_internal', { type: :float, order: 20 }
        add_available_filter 'sum_of_time_entries_expenses_external', { type: :float, order: 21 }
      end

      if User.current.allowed_to_globally?(:easy_money_show_other_expense, {})
        add_available_filter 'sum_of_other_expenses_price_2', { type: :float, order: 18 }
        add_available_filter 'sum_of_other_expenses_price_1', { type: :float, order: 14 }
        add_available_filter 'sum_of_all_other_expenses_price_1_internal', { type: :float, order: 30 }
        add_available_filter 'sum_of_all_other_expenses_price_2_internal', { type: :float, order: 31 }
        add_available_filter 'sum_of_all_other_expenses_price_1_external', { type: :float, order: 32 }
        add_available_filter 'sum_of_all_other_expenses_price_2_external', { type: :float, order: 33 }
      end
    end

    on_filter_group(l(:label_filter_group_easy_money_project_cache_revenues)) do
      add_available_filter 'sum_of_expected_revenues_price_1', { type: :float, order: 13 } if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      add_available_filter 'sum_of_other_revenues_price_1', { type: :float, order: 15 } if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      add_available_filter 'sum_of_expected_revenues_price_2', { type: :float, order: 17 } if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      add_available_filter 'sum_of_other_revenues_price_2', { type: :float, order: 19 } if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      add_available_filter 'sum_of_all_expected_revenues_price_1', { type: :float, order: 25 } if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      add_available_filter 'sum_of_all_other_revenues_price_1', { type: :float, order: 26 } if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      add_available_filter 'sum_of_all_expected_revenues_price_2', { type: :float, order: 28 } if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      add_available_filter 'sum_of_all_other_revenues_price_2', { type: :float, order: 29 } if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
    end

    on_filter_group(l(:label_filter_group_easy_money_project_cache_profit)) do
      if User.current.allowed_to_globally?(:easy_money_show_expected_profit, {})
        add_available_filter 'expected_profit_price_1', { type: :float, order: 34 }
        add_available_filter 'expected_profit_price_2', { type: :float, order: 35 }
      end

      if User.current.allowed_to_globally?(:easy_money_show_other_profit, {})
        add_available_filter 'other_profit_price_1_internal', { type: :float, order: 36 }
        add_available_filter 'other_profit_price_2_internal', { type: :float, order: 37 }
        add_available_filter 'other_profit_price_1_external', { type: :float, order: 38 }
        add_available_filter 'other_profit_price_2_external', { type: :float, order: 39 }
      end
    end

    on_filter_group(l(:label_filter_group_easy_money_project_cache_travel)) do
      if User.current.allowed_to_globally?(:easy_money_show_travel_cost, {})
        add_available_filter 'sum_of_all_travel_costs_price_1', { type: :float, order: 40 }
      end

      if User.current.allowed_to_globally?(:easy_money_show_travel_expense, {})
        add_available_filter 'sum_of_all_travel_expenses_price_1', { type: :float, order: 41 }
      end
    end

    add_associations_custom_fields_filters :project
  end

  def available_columns
    unless @available_columns_added
      group_expenses = l(:label_filter_group_easy_money_project_cache_expenses)
      group_revenues = l(:label_filter_group_easy_money_project_cache_revenues)
      group_profit   = l(:label_filter_group_easy_money_project_cache_profit)
      group_travel   = l(:label_filter_group_easy_money_project_cache_travel)

      @available_columns = [
          EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Project.table_name}.id"),
          EasyQueryColumn.new(:main_project),
          EasyQueryColumn.new(:sum_of_expected_hours, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_hours")
      ]
      @available_columns << EasyQueryColumn.new(:sum_of_expected_payroll_expenses, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_payroll_expenses", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_payroll_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_expected_expenses_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_expenses_price_1", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_expected_revenues_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_revenues_price_1", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_other_expenses_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_expenses_price_1", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_other_revenues_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_revenues_price_1", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_expected_expenses_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_expenses_price_2", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_expected_revenues_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_revenues_price_2", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_other_expenses_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_expenses_price_2", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_other_revenues_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_revenues_price_2", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      if User.current.allowed_to_globally?(:easy_money_show_time_entry_expenses, {})
        @available_columns << EasyQueryColumn.new(:sum_of_time_entries_expenses_internal, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_time_entries_expenses_internal", :group => group_expenses, query: self)
        @available_columns << EasyQueryColumn.new(:sum_of_time_entries_expenses_external, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_time_entries_expenses_external", :group => group_expenses, query: self)
      end
      @available_columns << EasyQueryColumn.new(:sum_of_estimated_hours, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_estimated_hours", :caption => :field_estimated_hours)
      @available_columns << EasyQueryColumn.new(:sum_of_timeentries, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_timeentries")
      @available_columns << EasyQueryColumn.new(:sum_of_all_expected_expenses_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_expenses_price_1", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_all_expected_revenues_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_revenues_price_1", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_all_other_revenues_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_revenues_price_1", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_all_expected_expenses_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_expenses_price_2", :group => group_expenses, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_expense, {})
      @available_columns << EasyQueryColumn.new(:sum_of_all_expected_revenues_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_revenues_price_2", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_expected_revenue, {})
      @available_columns << EasyQueryColumn.new(:sum_of_all_other_revenues_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_revenues_price_2", :group => group_revenues, query: self) if User.current.allowed_to_globally?(:easy_money_show_other_revenue, {})
      if User.current.allowed_to_globally?(:easy_money_show_other_expense, {})
        @available_columns << EasyQueryColumn.new(:sum_of_all_other_expenses_price_1_internal, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_1_internal", :group => group_expenses, query: self)
        @available_columns << EasyQueryColumn.new(:sum_of_all_other_expenses_price_2_internal, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_2_internal", :group => group_expenses, query: self)
        @available_columns << EasyQueryColumn.new(:sum_of_all_other_expenses_price_1_external, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_1_external", :group => group_expenses, query: self)
        @available_columns << EasyQueryColumn.new(:sum_of_all_other_expenses_price_2_external, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_2_external", :group => group_expenses, query: self)
      end

      if User.current.allowed_to_globally?(:easy_money_show_travel_cost, {})
        @available_columns << EasyQueryColumn.new(:sum_of_all_travel_costs_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_travel_costs_price_1", :group => group_travel, query: self)
      end

      if User.current.allowed_to_globally?(:easy_money_show_travel_expense, {})
        @available_columns << EasyQueryColumn.new(:sum_of_all_travel_expenses_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_travel_expenses_price_1", :group => group_travel, query: self)
      end

      if User.current.allowed_to_globally?(:easy_money_show_expected_profit, {})
        @available_columns << EasyQueryColumn.new(:expected_profit_price_1, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.expected_profit_price_1", :group => group_profit, query: self)
        @available_columns << EasyQueryColumn.new(:expected_profit_price_2, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.expected_profit_price_2", :group => group_profit, query: self)
      end
      if User.current.allowed_to_globally?(:easy_money_show_other_profit, {})
        @available_columns << EasyQueryColumn.new(:other_profit_price_1_internal, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_1_internal", :group => group_profit, query: self)
        @available_columns << EasyQueryColumn.new(:other_profit_price_2_internal, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_2_internal", :group => group_profit, query: self)
        @available_columns << EasyQueryColumn.new(:other_profit_price_1_external, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_1_external", :group => group_profit, query: self)
        @available_columns << EasyQueryColumn.new(:other_profit_price_2_external, :sumable => :both, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_2_external", :group => group_profit, query: self)
      end

      @available_columns << EasyQueryColumn.new(:profit_margin, :sortable => "#{EasyMoneyProjectCache.table_name}.profit_margin", :group => group_profit)

      @available_columns << EasyQueryColumn.new(:average_hourly_rate_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.average_hourly_rate_price_1", query: self)
      @available_columns << EasyQueryColumn.new(:average_hourly_rate_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.average_hourly_rate_price_2", query: self)

      @available_columns << EasyQueryColumn.new(:author, :groupable => "#{Project.table_name}.author_id", :sortable => Proc.new { User.fields_for_order_statement('authors') })
      c          = EasyQueryColumn.new(:parent_project, :sortable => "join_parent.name", :groupable => true, :joins => joins_for_parent_project_field, :caption => :field_project_parent)
      c.sortable = nil
      @available_columns << c

      @available_columns.concat(ProjectCustomField.sorted.visible.where(:show_on_list => true).collect { |cf| EasyQueryCustomFieldColumn.new(cf, :assoc => :project) })

      add_available_column :cost_ratio, sortable: "#{EasyMoneyProjectCache.table_name}.cost_ratio"

      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyMoneyProjectCache
  end

  def self.chart_support?
    true
  end

  def entity_scope
    @entity_scope ||= begin
      scope = EasyMoneyProjectCache.joins(:project).where(Project.allowed_to_condition(User.current, :view_easy_money))

      if EasyCurrency.activated.any?
        if easy_currency_code?
          scope = scope.where(entity.arel_table[:easy_currency_code].eq(easy_currency_code))
        else
          scope = scope.where(entity.arel_table[:easy_currency_code].eq(Project.arel_table[:easy_currency_code]))
        end
      else
        scope = scope.where(entity.arel_table[:easy_currency_code].eq(nil))
      end

      scope
    end
  end

  def sortable_columns
    c        = super
    c['lft'] = "#{Project.table_name}.lft"
    c
  end

  def default_find_include
    [:project]
  end

  def sql_for_author_id_field(field, operator, value)
    sql_for_field(field, operator, value, Project.table_name, 'author_id')
  end

  def sql_for_parent_id_field(field, operator, value)
    sql_for_field(field, operator, value, Project.table_name, 'parent_id')
  end

  def add_additional_order_statement_joins(order_options)
    sql = []
    if order_options.present?
      if order_options.include?('authors')
        sql << "LEFT OUTER JOIN #{User.quoted_table_name} authors ON authors.id = #{Project.quoted_table_name}.author_id"
      end
    end
    sql
  end

  def sql_for_is_project_closed_field(field, operator, value)
    o = value.first == '1' ? '=' : '<>'
    "(#{Project.table_name}.status #{o} #{Project::STATUS_CLOSED})"
  end

  def entity_easy_query_path(options)
    easy_money_project_caches_path(options)
  end

  def currency_columns?
    true
  end

  def project_statement(project_table = Project.table_name)
    project_clauses = []
    descendants     = self.project.descendants.active_and_planned.has_module(:easy_money) if self.project
    if self.project && !descendants.empty?
      ids = [self.project.id]
      if self.project.easy_money_settings.try(:include_childs?)
        if self.project.easy_is_easy_template
          ids.concat(descendants.templates.pluck(:id))
        else
          ids.concat(descendants.non_templates.pluck(:id))
        end
      end
      project_clauses << "(#{project_table}.id IN (%s) OR #{project_table}.id IS NULL)" % ids.join(',')
    elsif self.project
      project_clauses << "(#{project_table}.id = %d OR #{project_table}.id IS NULL)" % self.project.id
    elsif !self.project
      project_clauses << "(#{project_table}.easy_is_easy_template=#{self.class.connection.quoted_false} OR #{project_table}.easy_is_easy_template IS NULL)"
    end
    project_clauses.any? ? project_clauses.join(' AND ') : nil
  end

end
