class EasyProjectTemplateQuery < EasyQuery

  def query_after_initialize
    super
    self.easy_query_entity_controller = 'templates'
    self.export_formats               = ActiveSupport::OrderedHash.new
  end

  def self.entity_css_classes(project, options = {})
    project.css_classes(project.easy_level, options)
  end

  def entity_easy_query_path(options)
    templates_path options
  end

  def self.permission_view_entities
    :view_project
  end

  def initialize_available_filters
    on_filter_group(l('label_filter_group_easy_project_query')) do
      add_available_filter('name', { type: :text, order: 8 })
      add_available_filter('created_on', { type: :date_period, order: 12 })
      add_available_filter('updated_on', { type: :date_period, order: 13 })
    end
    add_available_filter 'easy_external_id', { type: :string }
    add_custom_fields_filters(EasyProjectTemplateCustomField)
  end

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column 'name', sortable: "#{Project.table_name}.name"
      add_available_column 'description', inline: true
      add_available_column 'easy_external_id', caption: :field_easy_external, sortable: "#{Project.table_name}.easy_external_id"
    end

    on_column_group(l('label_user_plural')) do
      add_available_column 'author', groupable: "#{Project.table_name}.author_id", sortable: lambda { User.fields_for_order_statement('authors') }
    end

    add_available_columns EasyProjectTemplateCustomField.sorted.visible.collect { |cf| EasyQueryCustomFieldColumn.new(cf)}
  end

  def searchable_columns
    return ["#{Project.table_name}.name"]
  end

  def entity
    Project
  end

  def entity_scope
    @entity_scope ||= Project.templates.active_and_planned
  end

  def columns_with_me
    super + ['member_id']
  end

  def extended_period_options
    {
        :extended_options       => [:to_today],
        :option_limit           => {
            :is_null        => ['easy_due_date', 'easy_start_date'],
            :is_not_null    => ['easy_due_date', 'easy_start_date'],
            :after_due_date => ['easy_due_date'],
            :next_week      => ['easy_due_date'],
            :tomorrow       => ['easy_due_date'],
            :next_5_days    => ['easy_due_date'],
            :next_7_days    => ['easy_due_date'],
            :next_10_days   => ['easy_due_date'],
            :next_30_days   => ['easy_due_date'],
            :next_90_days   => ['easy_due_date'],
            :next_month     => ['easy_due_date'],
            :next_year      => ['easy_due_date']
        },
        :field_disabled_options => {
            'not_updated_on' => [:is_null, :is_not_null]
        }
    }
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['lft', 'asc']]
  end

  def sortable_columns
    { 'lft' => "#{Project.table_name}.lft" }.merge(super)
  end

  def statement_skip_fields
    ['member_id', 'role_id', 'parent_id']
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{Project.table_name}.author_id"
      end
    end
    joins
  end

  def self.report_support?
    false
  end

end
