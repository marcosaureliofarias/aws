module ColumnDateHelpers

  def round_time(time, period)
    return nil if time.blank?
    # timezoneshit - not working
    # time = time.to_time.in_time_zone(User.current.time_zone || Time.zone || ActiveSupport::TimeZone["Etc/UTC"])
    time = time.to_time

    week_start_lamb = -> do
      start_of_week = Setting.start_of_week
      start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
      start_of_week.to_i
    end

    case period
    when :second
      time.change(:usec => 0)
    when :minute
      time.change(:sec => 0)
    when :hour
      time.change(:min => 0)
    when :day
      time.beginning_of_day
    when :week
      time.beginning_of_week(EasyUtils::DateUtils.day_of_week_start)
    when :month
      time.beginning_of_month
    when :quarter
      time.beginning_of_quarter
    when :year
      time.beginning_of_year
    when :hour_of_day
      time.hour
    when :day_of_week
      (7 - week_start_lamb.call + ((time.wday - 1) % 7) % 7)
    when :day_of_month
      time.day
    when :month_of_year
      time.month
    else
      raise "Invalid period"
    end
  end

end

class EasyQueryColumn < EasyEntityAttribute
  include EasyEntityAttributeColumnExtensions

  attr_accessor :query

  def initialize(name, options = {})
    @query = options[:query]
    super(name, options)
  end

  def date?
    false
  end

  def date_time?
    false
  end

  def group_by_statement(query)
    if polymorphic?
      polymorphic[:name].to_s + '_id'
    else
      res = sumable_sql || groupable
      if res.is_a?(String) && res.match(/^[\w\.]+$/)
        partial_name = res.match(/^[\w]+$/).present?
        entity_class = assoc_class || query.entity
        association  = entity_class.reflect_on_association(partial_name ? res.to_sym : self.entity_attribute_name)
        associated   = association && association.macro == :belongs_to # only count belongs_to associations
        res          = "#{entity_class.quoted_table_name}.#{associated ? association.foreign_key : res}" if associated || partial_name
      end
      res
    end
  end

end

class EasyQueryCustomFieldColumn < EasyEntityCustomAttribute
  include EasyEntityCustomAttributeColumnExtensions

  include ColumnDateHelpers

  def date?
    custom_field.date?
  end

  def date_time?
    custom_field.date_time?
  end

  def user_lookup?
    custom_field.field_format == 'easy_lookup' && custom_field.settings['entity_type'] == 'User'
  end

  def value(entity, options = {})
    val = super
    if date? && options[:period]
      round_time(val, options[:period])
    else
      val
    end
  end

  def group_by_statement(query)
    custom_field.format.period = query.group_by_period if date?
    sumable_sql || custom_field.group_statement
  ensure
    custom_field.format.period = nil if date?
  end

  def group
    @group || EasyQuery.column_filter_group_name(assoc_class && assoc_class.name.underscore)
  end

  def other_group?
    group.nil?
  end
end

class EasyQueryParameterizedColumn < EasyQueryColumn

  attr_accessor :method, :arguments

  def initialize(name, options = {})
    super(name, options)
    self.arguments = [*options[:arguments]]
    self.method    = options[:method]
  end

  def value(entity, options = {})
    method ? entity.nested_send(method.to_sym, *arguments) : super(entity, options)
  end

end

class EasyQueryPeriodColumn < EasyQueryColumn

  attr_accessor :options

  def initialize(name, options = {})
    @options = options.dup
    super(name, options)
  end

  def visible?
    false
  end

  def value(entity, options = {})
    query, period_idx = options[:query], options[:period_idx]

    return nil if query.nil? || period_idx.nil?

    entity.__send__(self.name, query.current_period_start_date(period_idx), query.current_period_end_date(period_idx), { :query => query }) if entity.respond_to?(self.name)
  end

  def generate(idx, query)
    EasyQueryPeriodGeneratedColumn.new(self, :period_idx => idx, :query => query)
  end

end

class EasyQueryPeriodGeneratedColumn < EasyQueryColumn

  def initialize(period_column, options = {})
    @query         = options[:query]
    @period_column = period_column
    @period_idx    = options[:period_idx]
    @start_date    = @query.current_period_start_date(@period_idx)
    @end_date      = @query.current_period_end_date(@period_idx)
    super(period_column.name, period_column.options.merge(options))
  end


  def value(entity, options = {})
    query = options[:query] || @query

    return nil if query.nil? || @period_idx.nil?

    entity.__send__(self.name, @start_date, @end_date, { :query => query }) if entity.respond_to?(self.name)
  end

end

class EasyQueryDateColumn < EasyQueryColumn

  include EasyExtensions::EasyQueryExtensions::DateTime
  include ColumnDateHelpers

  attr_reader :filter

  def initialize(name, options = {})
    @filter = options[:filter]
    super(name, options)
    @type = 'date'
  end

  def groupable
    value = super
    if value.nil?
      ((self.assoc.nil? || self.assoc_type != :has_many) && (self.sortable.is_a?(String) ? self.sortable : false))
    else
      value
    end
  end

  def date?
    true
  end

  def value(entity, options = {})
    time = super(entity)
    if options[:period]
      round_time(time, options[:period])
    else
      time
    end
  end

  def additional_group_by_for_sort(query, options = {})
    nil
  end

  def group_by_statement(query)
    column    = super
    statement = date_condition(column, query.group_by_period)
    Arel.sql(query.entity.send(:sanitize_sql_array, statement))
  end


  def group_by_sort_order(query, order = nil)
    Arel.sql("#{group_by_statement(query)} #{order || default_order || 'DESC'}")
  end

end

class EasyQueryCurrencyColumn < EasyQueryColumn

  attr_accessor :options

  def initialize(name, options = {})
    @options = options.dup
    super(name, options)
  end

  def easy_currency_code
    query.try(:easy_currency_code).presence
  end

  def sortable
    # Don't add a currency code if it's a Proc, define your own logic
    if easy_currency_code && !@options[:sortable].is_a?(Proc)
      result = "#{super}_#{easy_currency_code}"

      # This is quite a guessing but:
      #   - column is set as 'easy_money_expected_revenues.price1'
      #   - we need to change it to 'easy_money_expected_revenues.price1_EUR'
      #   - that is not valid on postgresql
      #   - it requires '"easy_money_expected_revenues"."price1_EUR"'
      #   - it cannot be set directly because currency could be changed
      if Redmine::Database.postgresql? && !result.include?('"')
        result = result.split('.').map {|w| EasyQuery.connection.quote_column_name(w) }.join('.')
      end

      result
    else
      super
    end
  end

  def value(entity, options = {})
    return nil if entity.nil?

    if @short_name && @assoc
      method_name = "#{@assoc}.#{@short_name}"
    else
      method_name = @name.to_s
    end
    if easy_currency_code
      if entity.class.respond_to?(:currency_options) && entity.class.currency_options.detect { |x| x[:price_method] == @name }
        method_name << "_#{easy_currency_code}"
      else
        return entity.nested_send(method_name, easy_currency_code)
      end
    end
    entity.nested_send(method_name)
  end

  def sumable_sql
    summable_sql = @sumable_sql.is_a?(Proc) ? @sumable_sql.call : @sumable_sql

    if easy_currency_code && summable_sql.is_a?(String)
      summable_sql.gsub(".#{@name}", ".#{currency_column_name}")
    elsif summable_sql.nil?
      if easy_currency_code.blank?
        @name.to_s
      else
        currency_column_name
      end
    else
      summable_sql
    end
  end

  def currency_column_name
    "#{@name}_#{easy_currency_code}".split('.').map { |n| EasyQuery.connection.quote_column_name(n) }.join('.')
  end

end

class EasyQuery < ActiveRecord::Base

  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  include Redmine::SubclassFactory
  include EasyUtils::DateUtils
  include Rails.application.routes.url_helpers

  include EasyExtensions::EasyQueryExtensions::Groupable
  include EasyExtensions::EasyQueryExtensions::DateTime
  include EasyQueriesConcerns::Calculations

  VISIBILITY_PRIVATE         = 0
  VISIBILITY_ROLES           = 1
  VISIBILITY_PUBLIC          = 2
  VISIBILITY_EASY_USER_TYPES = 3

  DEFAULT_SORTING_SUFFIX = 'default_sorting_array'

  ENTITY_OBJECT = Struct.new(:id, :to_s)

  belongs_to :project
  belongs_to :user
  has_and_belongs_to_many :roles, :join_table => "#{table_name_prefix}easy_queries_roles#{table_name_suffix}", :foreign_key => 'easy_query_id'
  has_and_belongs_to_many :easy_user_types, :join_table => "#{table_name_prefix}easy_queries_easy_user_types#{table_name_suffix}", :foreign_key => 'easy_query_id'
  belongs_to :easy_currency, foreign_key: :easy_currency_code, primary_key: :iso_code

  has_one :source_query, :through => :copy_from, :source => :entity_from, :source_type => 'EasyQuery'
  has_one :copy_from, :class_name => 'EasyEntityAssignment', :dependent => :destroy, :as => :entity_from, :foreign_key => 'entity_to_id', :foreign_type => 'entity_to_type'
  has_many :copy_to, :class_name => 'EasyEntityAssignment', :dependent => :destroy, :as => :entity_to, :foreign_key => 'entity_from_id', :foreign_type => 'entity_from_type'
  has_one :easy_query_snapshot, foreign_key: 'easy_query_id', dependent: :destroy
  has_many :query_copies, :through => :copy_to, :source => :entity_to, :source_type => 'EasyQuery'
  has_many :easy_default_query_mappings, dependent: :destroy
  has_many :default_for_roles, through: :easy_default_query_mappings, class_name: 'Role'

  accepts_nested_attributes_for :easy_query_snapshot, allow_destroy: true

  scope :sorted, lambda { order("#{EasyQuery.table_name}.name") }
  scope :named, lambda { |type, term| where(type: type).eager_load(:user).where("#{Redmine::Database.like("#{table_name}.name", ':term')} OR #{Redmine::Database.like("#{User.table_name}.firstname", ':term')} OR #{Redmine::Database.like("#{User.table_name}.lastname", ':term')}", { term: "%#{term}%" }) }

  class_attribute :queried_class

  store :filters, coder: JSON
  store :custom_formatting, coder: JSON
  store :settings, coder: JSON
  store :chart_settings, coder: JSON

  serialize :group_by, JSON

  serialize :column_names, Array
  serialize :sort_criteria, Array
  serialize :outputs, Array
  serialize :period_settings, EasyExtensions::EasyQueryHelpers::PeriodSetting

  attr_reader :sort_helper

  attr_accessor :additional_statement, :additional_statement_added
  attr_accessor :additional_scope
  attr_accessor :render_context
  attr_accessor :display_filter_columns_on_index, :display_filter_group_by_on_index, :display_filter_sort_on_index
  attr_accessor :display_filter_settings_on_index, :display_outputs_select_on_index, :display_outputs_select_on_edit
  attr_accessor :display_filter_columns_on_edit, :display_filter_group_by_on_edit, :display_filter_sort_on_edit
  attr_accessor :display_filter_settings_on_edit
  attr_accessor :display_filter_fullscreen_button, :display_save_button
  attr_accessor :display_project_column_if_project_missing
  attr_accessor :display_show_sum_row, :display_load_groups_opened
  attr_accessor :easy_query_entity_action
  attr_accessor :require_is_tagged
  attr_accessor :easy_query_entity_partial_view, :export_formats, :open_categories_ids, :count_on_different_column
  attr_accessor :use_free_search, :free_search_question, :free_search_tokens
  attr_accessor :entity_scope
  attr_accessor :source_entity, :use_referenced_collection_scope, :referenced_collection_name, :source_entity_type, :source_entity_id
  attr_accessor :easy_page_module
  attr_accessor :dont_use_project, :force_current_project_filter
  attr_accessor :modal_selector
  attr_accessor :original_query
  attr_accessor :display_as_tree_with_expander_on_root
  attr_writer :custom_formatting_entities, :easy_query_entity_controller, :disable_columns

  # Controls how {#entity_sum} will react
  # @return [Symbol, String] a aggregation symbol (:sum, :average, ...)
  attr_accessor :aggregate_by

  #prechodny parametr - melo by se premigrovat, ale prozatim
  attr_accessor :loading_group

  validates :name, :presence => true
  validates_length_of :name, :maximum => 255
  validates :visibility, :inclusion => { :in => [VISIBILITY_PUBLIC, VISIBILITY_ROLES, VISIBILITY_PRIVATE, VISIBILITY_EASY_USER_TYPES] }
  validate :validate_query_filters
  validate do |query|
    if query.visibility == VISIBILITY_ROLES && roles.blank?
      errors.add(:base, l(:label_role_plural) + ' ' + l('activerecord.errors.messages.blank'))
    elsif query.visibility == VISIBILITY_EASY_USER_TYPES && easy_user_types.blank?
      errors.add(:base, l(:label_easy_user_type_plural) + ' ' + l('activerecord.errors.messages.blank'))
    end
  end

  after_initialize :query_after_initialize

  before_save do |query|
    self.is_tagged = true if self.require_is_tagged?
  end

  after_save do |query|
    if query.saved_change_to_visibility? && query.visibility != VISIBILITY_ROLES
      query.roles.clear
    end
  end

  class_attribute :registered_subclasses
  self.registered_subclasses = {}

  class_attribute :operators
  self.operators = {
      '='     => :label_equals,
      '!'     => :label_not_equals,
      'o'     => :label_open_issues,
      'c'     => :label_closed_issues,
      '!*'    => :label_none,
      '*'     => :label_any,
      '>='    => :label_greater_or_equal,
      '<='    => :label_less_or_equal,
      '><'    => :label_between,
      '<t+'   => :label_in_less_than,
      '>t+'   => :label_in_more_than,
      '><t+'  => :label_in_the_next_days,
      't+'    => :label_in,
      't'     => :label_today,
      'ld'    => :label_yesterday,
      'w'     => :label_this_week,
      'lw'    => :label_last_week,
      'l2w'   => [:label_last_n_weeks, { :count => 2 }],
      'm'     => :label_this_month,
      'lm'    => :label_last_month,
      'y'     => :label_this_year,
      '>t-'   => :label_less_than_ago,
      '<t-'   => :label_more_than_ago,
      '><t-'  => :label_in_the_past_days,
      't-'    => :label_ago,
      '~'     => :label_contains,
      '!~'    => :label_not_contains,
      '^~'    => :label_starts_with,
      '$~'    => :label_ends_with,
      '=p'    => :label_any_issues_in_project,
      '=!p'   => :label_any_issues_not_in_project,
      '!p'    => :label_no_issues_in_project,
      '*o'    => :label_any_open_issues,
      '!o'    => :label_no_open_issues,
      '>dd'   => :label_after_due_date,
      'only=' => :label_only
  }

  class_attribute :operators_by_filter_type
  self.operators_by_filter_type = {
      boolean:           ['='],
      list:              ['=', '!'],
      list_autocomplete: ['=', '!', '!*', '*'],
      list_status:       ['o', '=', '!', 'c', '*'],
      list_version:      ['o', 'c', '>dd', '=', '!', '!*', '*'],
      list_optional:     ['=', '!', '!*', '*'],
      list_subprojects:  ['*', '!*', '=', '!', 'only='],
      date:              ['=', '>=', '<=', '><', '<t+', '>t+', '><t+', 't+', 't', 'ld', 'w', 'lw', 'l2w', 'm', 'lm', 'y', '>t-', '<t-', '><t-', 't-', '!*', '*'],
      date_past:         ['=', '>=', '<=', '><', '>t-', '<t-', '><t-', 't-', 't', 'ld', 'w', 'lw', 'l2w', 'm', 'lm', 'y', '!*', '*'],
      date_period:       ['date_period_1', 'date_period_2', '=', '>=', '<=', '><', '>t-', '<t-', '><t-', 't-', 't', 'ld', 'w', 'lw', 'l2w', 'm', 'lm', 'y', '!*', '*'],
      string:            ['=', '~', '!', '!~', '^~', '$~', '!*', '*'],
      text:              ['~', '!~', '^~', '$~', '!*', '*'],
      integer:           ['=', '>=', '<=', '><', '!*', '*'],
      float:             ['=', '>=', '<=', '><', '!*', '*'],
      currency:          ['=', '>=', '<=', '><', '!*', '*'],
      relation:          ['=', '=p', '=!p', '!p', '*o', '!o', '!*', '*'],
      tree:              ["=", "~", "!*", "*"],
      easy_lookup:       ['=', '!'],
      country_select:    ['=']
  }

  class_attribute :hidden_values_by_operator
  self.hidden_values_by_operator = ['!*', '*', 't', 'w', 'o', 'c', '*o', '!o']

  def self.default_url_options
    Mailer.default_url_options
  end

  def self.disabled_sti_class
    EasyDisabledQuery
  end

  def self.visible(user = nil, options = {})
    user ||= User.current

    scope = joins("LEFT OUTER JOIN #{Project.quoted_table_name} ON #{quoted_table_name}.project_id = #{Project.quoted_table_name}.id").preload(:project)

    permission_view_entities = options[:query_class] ? options[:query_class].permission_view_entities : self.permission_view_entities

    if permission_view_entities.nil?
      scope = scope.where("#{table_name}.project_id IS NULL")
    else
      base  = Project.allowed_to_condition(user, permission_view_entities, options)
      scope = scope.where("#{table_name}.project_id IS NULL OR (#{base})")
    end
    # external client can only see private queries and queries with user type
    if user.external_client?
      scope = scope.where("#{table_name}.visibility = ?" +
                              " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
                              "SELECT DISTINCT q.easy_query_id FROM #{table_name_prefix}easy_queries_easy_user_types#{table_name_suffix} q WHERE q.easy_user_type_id = ?" +
                              "))", VISIBILITY_PRIVATE, VISIBILITY_EASY_USER_TYPES, user.easy_user_type_id)
    end
    if !options[:ignore_admin] && user.admin?
      scope.where("#{table_name}.visibility <> ? OR #{table_name}.user_id = ?", VISIBILITY_PRIVATE, user.id)
    elsif user.memberships.any?
      scope.where("#{table_name}.visibility = ?" +
                      " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
                      "SELECT DISTINCT q.id FROM #{table_name} q" +
                      " INNER JOIN #{table_name_prefix}easy_queries_roles#{table_name_suffix} qr on qr.easy_query_id = q.id" +
                      " INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = qr.role_id" +
                      " INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
                      " INNER JOIN #{Project.table_name} p ON p.id = m.project_id AND p.status <> ?" +
                      " WHERE q.project_id IS NULL OR q.project_id = m.project_id))" +
                      " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
                      "SELECT DISTINCT q.easy_query_id FROM #{table_name_prefix}easy_queries_easy_user_types#{table_name_suffix} q WHERE q.easy_user_type_id = ?" +
                      "))" +
                      " OR (#{table_name}.visibility = ? AND #{table_name}.user_id = ?)",
                  VISIBILITY_PUBLIC, VISIBILITY_ROLES, user.id, Project::STATUS_ARCHIVED, VISIBILITY_EASY_USER_TYPES, user.easy_user_type_id, VISIBILITY_PRIVATE, user.id)
    elsif user.logged?
      scope.where("#{table_name}.visibility = ? OR #{table_name}.user_id = ?", VISIBILITY_PUBLIC, user.id)
    else
      scope.none
    end
  end

  def self.for_project(project)
    preload(:project).where(project.nil? ? ['project_id IS NULL'] : ['project_id IS NULL OR project_id = ? OR EXISTS(SELECT q.* FROM easy_queries q INNER JOIN projects qp ON qp.id = q.project_id WHERE q.id = easy_queries.id AND q.is_for_subprojects = ? AND qp.lft < ? AND qp.rgt > ?)', project.id, true, project.lft, project.rgt])
  end

  def self.sidebar_queries(visibility, user = nil, project = nil, options = {})
    scope = visible(user, options).where(easy_queries: { visibility: visibility }).select([:id, :name, :sort_criteria, :project_id, :type, :visibility, :filters]).sorted
    scope = scope.for_project(project) unless project === false

    # By default all subclasses are included
    # EasyIssueQuery => type IN ('EasyIssueQuery', 'EasyAgileBoardQuery')
    #
    if options[:query_class]
      # Specific class
      scope = scope.where(type: options[:query_class])
    elsif options[:with_subclasses]
      # Already done
    else
      # Include only self
      # First make sure what is current class
      # role.easy_queries.where(type: EasyIssueQuery).role_queries => self.name == EasyQuery
      scope = scope.where(type: self.name)
    end

    scope
  end

  def self.private_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_PRIVATE, user, project, options)
  end

  def self.public_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_PUBLIC, user, project, options)
  end

  def self.role_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_ROLES, user, project, options)
  end

  def self.tagged_queries(user = nil, project = nil, options = {})
    visible(user, options).for_project(project).where(:is_tagged => true).
        where(:type => self.name).order("#{table_name}.name ASC")
  end

  def self.map(&block)
    yield self
  end

  def self.register(query_class, options = {})
    # EasySetting required ['default_sorting_array', 'default_filters', 'list_default_columns', 'grouped_by']
    if query_class.is_a?(Class)
      ActiveSupport::Deprecation.warn "Passing a query class #{query_class} is deprecated, use a string"
      query_class = query_class.to_s
    end
    registered_subclasses[query_class] = options unless registered_subclasses.key?(query_class)
  end

  def self.constantized_subclasses
    registered_subclasses.keys.map(&:constantize)
  end

  def self.entity_css_classes(entity, options = {})
    entity.css_classes if entity.respond_to?(:css_classes)
  end

  def self.permission_view_entities
    nil
  end

  def self.translated_name
    I18n.t(name.underscore, :scope => [:easy_query, :name], :default => name.underscore)
  end

  # Create missing settings for all subclasses
  # Method can be called more times -> will not create duplicates
  #
  # == New Query
  #  class EasyMyQuery < EasyQuery
  #  end
  #
  #  EasyQuery.create_missing_sorting_criteria!({'easy_my_query' => [['subject', 'asc']]})
  #
  def self.create_missing_sorting_criteria!(default_criteria = {})
    EasyQuery.subclasses.each do |query|
      name = "#{query.name.underscore}_#{DEFAULT_SORTING_SUFFIX}"

      # Already exists
      next if EasySetting.exists?(name: name)

      value = default_criteria[query.name.underscore] || []

      EasySetting.create!(name: name, value: value)
    end
  end

  # Delete saved queries with invalide type
  def self.delete_invalid_subclasses
    saved_types = EasyQuery.distinct.pluck(:type)
    saved_types.each do |type|
      begin
        type.constantize
      rescue LoadError, NameError
        EasyQuery.where(type: type).delete_all
      end
    end
  end

  def self.remote_filter_types
    %i(list_autocomplete)
  end

  def remote_filter?(filter = {})
    EasyQuery.remote_filter_types.include?(filter[:type])
  end

  #TO OVERRIDE!
  def initialize_available_filters
    @available_filters = []
  end

  def initialize_available_columns
    @available_columns = []
  end

  def entity
    self.class.queried_class
  end

  def easy_currency_code
    original_query.nil? ? super : original_query.easy_currency_code
  end

  def easy_query_entity_controller
    @easy_query_entity_controller ||= self.entity.name.underscore.pluralize
  end

  def queried_class
    self.class.queried_class || self.entity
  end

  def entity_table_name
    @entity_table_name ||= entity.table_name
  end

  def default_find_include
    []
  end

  def default_find_joins
    []
  end

  def default_find_preload
    []
  end

  def default_groups_preload
    []
  end

  def default_column_groups_ordering
    [
        l(:label_most_used),
        default_group_label
    ]
  end

  def filter_groups_ordering
    default_column_groups_ordering
  end

  def column_groups_ordering
    default_column_groups_ordering
  end

  def default_list_columns
    get_default_values_from_easy_settings('list_default_columns') || Array.new
  end

  def default_name
    l(self.class.name.underscore, :scope => [:easy_query, :name])
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}")
  end

  def searchable_columns
    []
  end

  def columns_with_me
    (@columns_with_me.to_a + ['user_id', 'assigned_to_id', 'author_id', 'watcher_id']).uniq
  end

  def add_columns_with_me(*args)
    @columns_with_me ||= []
    @columns_with_me += args.flatten.uniq
  end

  def columns_with_position
    @columns_with_position ||= self.groupable_columns.collect { |gc| gc.name.to_s.underscore if Array(gc.sortable).join('').include?('.position') }.compact
  end


  # OTHERS

  # def initialize(attributes = nil)
  #   raise NotImplementedError, 'You have override entity method!' if self.entity.nil?
  #   super attributes
  #   #raise NotImplementedError, 'You have override available_columns method!' if self.available_columns.blank?
  #   #raise NotImplementedError, 'You have override default_list_columns method!' if self.default_list_columns.blank?
  #   #self.filters = self.default_filter if self.filters.blank?
  #   self.custom_formatting = self.default_custom_formatting if self.custom_formatting.blank?
  # end

  def query_after_initialize
    self.additional_statement, self.additional_statement_added                                                     = '', false
    self.display_filter_columns_on_index, self.display_filter_group_by_on_index, self.display_filter_sort_on_index = true, true, false
    self.display_filter_settings_on_index                                                                          = true
    self.display_outputs_select_on_index                                                                           = true
    self.display_outputs_select_on_edit                                                                            = true
    self.display_filter_columns_on_edit, self.display_filter_group_by_on_edit, self.display_filter_sort_on_edit    = true, true, true
    self.display_filter_settings_on_edit                                                                           = true
    self.display_save_button                                                                                       = true
    self.display_project_column_if_project_missing                                                                 = true
    self.display_show_sum_row                                                                                      = true
    self.display_load_groups_opened                                                                                = true
    self.easy_query_entity_partial_view                                                                            = 'easy_queries/easy_query_entities_list'
    self.force_current_project_filter                                                                              = false
    self.display_as_tree_with_expander_on_root                                                                     = true
    export              = ActiveSupport::OrderedHash.new
    export[:csv]        = {}
    export[:xlsx]       = {}
    export[:pdf]        = {}
    self.export_formats = export
  end

  def easy_query_entity_action
    @easy_query_entity_action || 'index'
  end

  def to_partial_path
    'easy_queries/easy_query'
  end

  def calendar_class
    Redmine::Helpers::Calendar
  end

  def calendar_options
    {}
  end

  # Removes an available column
  def delete_available_column(column_name)
    if @available_columns
      @available_columns.delete_if { |column| column.name == column_name.to_sym }
    end
  end

  def available_columns
    unless @available_columns_added
      initialize_available_columns

      @available_columns_added = true
    end

    @available_columns
  end

  def add_available_column(name_or_column, options = {})
    return if name_or_column.nil?
    if !options.has_key?(:group) && @current_column_group
      options[:group] = @current_column_group
    end

    @available_columns ||= []

    if name_or_column.is_a?(EasyEntityAttribute)
      name_or_column.group = @current_column_group if @current_column_group && name_or_column.other_group?
      @available_columns << name_or_column
    else
      @available_columns << EasyQueryColumn.new(name_or_column.to_sym, options)
    end
  end

  def add_available_columns(columns)
    Array(columns).each do |column|
      add_available_column(column)
    end
  end

  def add_associated_columns(easy_query_class, options = {})
    q                = easy_query_class.new
    q.project        = project
    q.original_query = self

    association_name   = (options[:association_name] || q.entity.name.underscore).to_sym
    column_name_prefix = options[:column_name_prefix] || "#{options[:association_name] ? options[:association_name].to_s.pluralize : q.entity.table_name}."
    only               = options[:only]

    association  = self.entity.reflect_on_association(association_name)
    is_groupable = if options[:is_groupable].nil?
                     association.nil? || association.belongs_to? || association.has_one?
                   else
                     options[:is_groupable]
                   end

    q.available_columns.each do |origin_column|
      next if origin_column.assoc_column? && !options[:all]

      # User can choose what filters are wanted
      next if only && only.none? { |token| token === origin_column.name }

      new_column            = origin_column.dup
      new_column.name       = "#{column_name_prefix}#{origin_column.name}".to_sym
      new_column.short_name = origin_column.name

      if origin_column.is_a?(EasyQueryParameterizedColumn)
        if !association.nil? && (association.belongs_to? || association.has_one?) && !origin_column.method.nil?
          new_column.method = "#{association_name}.#{origin_column.method}"
        else
          next
        end
      end

      if /\A.+ \(.+\)\z/.match?(origin_column.caption.to_s)
        new_column.title = origin_column.caption
      else
        new_column.title = "#{origin_column.caption} (#{q.default_name})"
      end

      if options[:group_name].present?
        group_name = options[:group_name]
        if new_column.is_a?(EasyQueryCustomFieldColumn)
          group_name += " #{l(:label_filter_group_custom_fields_suffix)}"
        end
        new_column.group = group_name
      end
      new_column.assoc       = association_name
      new_column.assoc_query = q
      new_column.assoc_type  = association.macro if association
      new_column.sortable    = false unless is_groupable
      new_column.groupable   = false unless is_groupable
      new_column.groupable   = "#{q.entity.quoted_table_name}.#{q.quote_column_name('id')}" if options[:groupable] == origin_column.name
      new_column.includes    = Array.wrap(new_column.includes).map { |i| { association_name => i } } << association_name
      new_column.includes << { association_name => q.default_find_include } if q.default_find_include.any?
      new_column.preload = Array.wrap(new_column.preload).map { |i| { association_name => i } }

      if origin_column.sumable
        new_column.sumable = options[:sumable] if options[:sumable]
        new_column.sumable_options = { model: options[:common_sumable_options][:model],
                                       column: origin_column.name,
                                       distinct_columns: options[:common_sumable_options][:distinct_columns] } if options[:common_sumable_options]
      end
      # new_column.joins = Array.wrap(new_column.joins).map {|i| {association_name => i}}

      add_available_column(new_column)
    end
  end

  def add_available_filters(filters)
    filters.each do |filter, options|
      add_available_filter(filter, options)
    end
  end

  # Adds an available filter
  def add_available_filter(field, options = {})
    return @available_filters if options[:permitted] == false

    if !options.has_key?(:group) && @current_filter_group
      options[:group] = @current_filter_group
    end

    options[:type] ||= :string

    @available_filters        ||= ActiveSupport::OrderedHash.new
    @available_filters[field] = options
    @available_filters
  end

  def add_principal_autocomplete_filter(field, options = {})
    default_options = {
        type:           :list_autocomplete,
        source:         'visible_principals',
        source_root:    'users',
        data_type:      :user,
        source_options: {
            project_id: project&.id
        },
        klass:          Principal
    }
    add_available_filter(field, default_options.deep_merge(options))
  end

  # Removes an available filter
  def delete_available_filter(field)
    if @available_filters
      @available_filters.delete(field)
    end
  end

  # Return a hash of available filters
  def available_filters
    unless @available_filters
      initialize_available_filters
      @available_filters.each do |field, options|
        options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
      end
    end
    @available_filters
  end

  def on_column_group(group)
    old_column_group      = @current_column_group
    @current_column_group = group
    yield
  ensure
    @current_column_group = old_column_group
  end

  def on_filter_group(group)
    old_filter_group      = @current_filter_group
    @current_filter_group = group
    yield
  ensure
    @current_filter_group = old_filter_group
  end

  def validate_query_filters
    filters.each_key do |field|
      if values_for(field)
        case type_for(field)
        when :integer
          add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !(/\A[+-]?\d+(,[+-]?\d+)*\z/.match?(v)) }

        when :float, :currency
          add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !(/\A[+-]?\d+(\.\d*)?\z/.match?(v)) }

        when :date, :date_past, :date_range
          case operator_for(field)
          when '=', '>=', '<=', '><'
            add_filter_error(field, :invalid) if values_for(field).detect { |v|
              v.present? && (!(/\A\d{4}-\d{2}-\d{2}(T\d{2}((:)?\d{2}){0,2}(Z|\d{2}:?\d{2})?)?\z/.match?(v)) || parse_date(v).nil?)
            }
          when '>t-', '<t-', 't-', '>t+', '<t+', 't+', '><t+', '><t-'
            add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !(/^\d+$/.match?(v)) }
          end

        when :relation
          operator = operator_for(field)
          unless ['!*', '*', '*o', '!o'].include?(operator)
            add_filter_error(field, :easy_query_filter_relation_invalid) unless values_for(field).detect { |v| v.present? }
          end

        when :list_autocomplete, :list_status, :list_version, :list_optional, :list_subprojects
          if entity && column = entity.columns.find { |column| column.name == field }
            case column.type
            when :integer
              operator = operator_for(field)
              unless ['o', 'c'].include?(operator)
                add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !integer_value_valid?(field, v) }
              end
            end
          end
        end

      end
    end if filters
  end

  def add_filter_error(field, message)
    m = label_for(field) + " " + l(message, :scope => 'activerecord.errors.messages')
    errors.add(:base, m)
  end

  def integer_value_valid?(field, value)
    return true if /\A[+-]?\d+(,[+-]?\d+)*\z/.match?(value)
    return true if @available_filters[field][:klass] && @available_filters[field][:klass] <= Principal && value.in?(['me', 'me_and_my_groups'])
    return true if field.in?(['project_id', 'xproject_id']) && value.in?(['mine', 'current'])
    false
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (self.is_private? && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    self.is_public? && self.is_for_all? ? user.allowed_to_globally?(:manage_public_queries) : user.allowed_to?(:manage_public_queries, self.project)
  end

  def visible?(user = User.current)
    return true if user.admin?
    return false unless project.nil? || user.allowed_to?(self.class.permission_view_entities, project, :global => true)
    case visibility
    when VISIBILITY_PUBLIC
      true
    when VISIBILITY_ROLES
      if project
        (user.roles_for_project(project) & roles).any?
      else
        user.memberships.joins(:member_roles).where(:member_roles => { :role_id => roles.map(&:id) }).any?
      end
    when VISIBILITY_EASY_USER_TYPES
      easy_user_types.where(:id => user.easy_user_type_id).any?
    else
      user == self.user
    end
  end

  def visible_by_entities
    visible_entities = []
    case visibility
    when VISIBILITY_ROLES
      visibility_title = :label_role_plural
      visible_entities = roles
    when VISIBILITY_EASY_USER_TYPES
      visibility_title = :label_easy_user_type_plural
      visible_entities = easy_user_types
    when VISIBILITY_PRIVATE
      visibility_title = :field_author
    when VISIBILITY_PUBLIC
      visibility_title = :label_everyone
    end
    { visibility_title: visibility_title, visible_entities: visible_entities }
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def is_tagged?
    self.require_is_tagged? || super
  end

  alias_method :is_tagged, :is_tagged?

  def is_for_all?
    self.project_id.nil?
  end

  # Returns a representation of the available filters for JSON serialization
  def available_filters_as_json
    json = {}
    available_filters.each do |field, options|
      options = options.slice(:type, :name, :values)
      if options[:values] && values_for(field)
        options[:values] = options[:values].call if options[:values].is_a?(Proc)
        missing          = Array(values_for(field)).select(&:present?) - options[:values].map(&:last)
        if missing.any? && respond_to?(method = "find_#{field}_filter_values")
          options[:values] += send(method, missing)
        end
      end
      json[field] = options.stringify_keys
    end
    json
  end

  # Get values from Proc, select only valid filters, sort and cache list of filters. Return array of arrays
  def filters_for_select(sort_by = 'name')
    case sort_by
    when 'name'
      @filters_for_select ||= self.available_filters.sort { |a, b| (a[1][:name] || '-') <=> (b[1][:name] || '-') }
    when 'order'
      @filters_for_select ||= self.available_filters.sort { |a, b| (a[1][:order] || 999) <=> (b[1][:order] || 999) }
    else
      []
    end
  end

  def reader_filters
    @reader_filters ||= filters_for_select.select { |_, options| options[:attr_reader] }
  end

  def writer_filters
    @writer_filters ||= filters_for_select.select { |_, options| options[:attr_writer] }
  end

  def custom_formatting_entities
    generate_custom_formatting_entities_hash if @custom_formatting_entities.nil?
    @custom_formatting_entities
  end

  def add_custom_formatting_from_params(params)
    self.custom_formatting = {}
    schemes                = params.select { |k, _| k.to_s.start_with?('scheme-') }
    schemes.each do |scheme, filters|
      self.custom_formatting[scheme] ||= {}
      if filters['fields'] && filters['operators'] && filters['values']
        filters['fields'].each do |field|
          self.add_filter(field, filters['operators'][field], filters['values'][field], self.custom_formatting[scheme])
        end
      else
        filters.each do |field, value|
          self.add_short_filter(field, value, self.custom_formatting[scheme])
        end
      end
    end
  end

  def generate_custom_formatting_entities_hash
    return if self.custom_formatting.blank?
    self.custom_formatting_entities = {}

    self.custom_formatting.each do |scheme, filters|
      self.new_entity_scope.where(self.statement(filters)).pluck(:id).each do |entity_id|
        self.custom_formatting_entities[entity_id] = scheme
      end
    end
  end

  def projects_for_select(projects = nil, cache = true)
    return @project_values if @project_values.present? && cache
    @project_values = Array.new
    Project.each_with_easy_level(projects || Project.visible.non_templates.sorted) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      @project_values << ["#{prefix}#{p.name}", p.id.to_s]
    end

    return @project_values
  end

  def project_module
    nil
  end

  def all_projects(with_enabled_module = true)
    return @all_projects if @all_projects

    @all_projects = Project.visible.non_templates.sorted.select(%i[id name easy_level parent_id lft rgt])
    @all_projects = @all_projects.has_module(project_module) if with_enabled_module && project_module

    @all_projects
  end

  def all_subprojects_values
    return @all_subprojects_values if @all_subprojects_values

    if project && !project.leaf?
      if project.easy_is_easy_template?
        subprojects = project.descendants.visible.templates.select([:id, :name, :easy_level])
      else
        subprojects = project.descendants.visible.non_templates.select([:id, :name, :easy_level])
      end
    else
      subprojects = Project.active.sorted
    end

    @all_subprojects_values = subprojects.map { |s| [s.name, s.id.to_s] }
  end

  def all_projects_values(options = {})
    unless @all_projects_values
      values = []
      Project.each_with_easy_level(all_projects) do |p, level|
        prefix = (level > 0 ? ('--' * level + ' ') : '')
        values << ["#{prefix}#{p.name}", p.id.to_s]
      end
      @all_projects_values = values
    end
    if options[:include_mine] && User.current.logged?
      mine_value = [["<< #{l(:label_my_projects).downcase} >>", 'mine']]
      mine_value.concat(@all_projects_values)
    else
      @all_projects_values
    end
  end

  def all_projects_parents(main_only = false)
    main_cond = 'AND projects.parent_id IS NULL' if main_only
    all_projects(!main_only).where("rgt - lft > 1 #{main_cond}")
  end

  def all_projects_parents_values(main_only = false)
    @all_parents_values ||= {}
    return @all_parents_values[main_only] if @all_parents_values[main_only]
    values = []
    Project.each_with_easy_level(all_projects_parents(main_only).select([:id, :name, :easy_level])) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      values << ["#{prefix}#{p.name}", p.id.to_s]
    end
    @all_parents_values[main_only] = values
  end

  def all_main_projects_values
    all_projects_parents_values(true)
  end

  def all_countries_values
    ISO3166::Country.all_names_with_codes(I18n.locale)
  end

  def all_principals
    @all_principals ||= (self.project ? self.project.principals : Principal).active.visible.sorted.reject { |p| p.is_a?(GroupBuiltin) }
  end

  def all_principals_values
    all_principals.map { |p| [p.to_s, p.id.to_s] }
  end

  def all_users
    @all_users ||= all_principals.select { |p| p.is_a?(User) }
  end

  def all_users_values(options = {})
    if options[:include_groups]
      all_values = all_principals
    else
      all_values = all_users
    end

    users_values = []
    if User.current.logged? && options[:include_me]
      users_values << ["<< #{l(:label_me)} >>", 'me']
      users_values << ["<< #{l(:label_me_and_my_groups)} >>", 'me_and_my_groups'] if options[:include_groups]
    end
    all_values.each { |u| users_values << [u.to_s, u.id.to_s] }
    users_values
  end

  def author_values
    all_users_values(:include_me => true)
  end

  def all_groups
    @all_groups ||= all_principals.select { |p| p.is_a?(Group) }
  end

  def all_groups_values
    all_groups.map { |u| [u.to_s, u.id.to_s] }
  end

  def all_tags_values
    ActsAsTaggableOn::Tag.joins(:taggings).where(:taggings => { :context => 'tags' }).order('tags.name asc').distinct.pluck(:name)
  end

  def joins_for_parent_project_field
    main_entity   = entity.arel_table
    project       = Project.arel_table.alias('join_project')
    parent        = Project.arel_table.alias('join_parent')
    join_projects = main_entity.create_on(main_entity[:project_id].eq(project[:id]))
    join_parents  = project.create_on(project[:parent_id].eq(parent[:id]).and(parent[:rgt] - parent[:lft].gt(1)))
    main_entity.create_join(project, join_projects, Arel::Nodes::OuterJoin).to_sql + ' ' + project.create_join(parent, join_parents, Arel::Nodes::OuterJoin).to_sql
  end

  def joins_for_parent_category_field
    main_entity           = entity.arel_table
    category              = IssueCategory.arel_table.alias('join_category')
    parent                = IssueCategory.arel_table.alias('join_category_parent')
    join_categories       = main_entity.create_on(main_entity[:category_id].eq(category[:id]))
    join_category_parents = category.create_on(category[:parent_id].eq(parent[:id]).and(parent[:rgt] - parent[:lft].gt(1)))
    main_entity.create_join(category, join_categories, Arel::Nodes::OuterJoin).to_sql + ' ' + category.create_join(parent, join_category_parents, Arel::Nodes::OuterJoin).to_sql
  end

  def joins_for_root_category_field
    main_entity         = entity.arel_table
    category            = IssueCategory.arel_table.alias('join_category2')
    root                = IssueCategory.arel_table.alias('join_category_root')
    join_categories     = main_entity.create_on(main_entity[:category_id].eq(category[:id]))
    join_category_roots = category.create_on(root[:parent_id].eq(nil).and(root[:lft].lteq(category[:lft]).and(root[:rgt].gteq(category[:rgt]))))
    main_entity.create_join(category, join_categories, Arel::Nodes::OuterJoin).to_sql + ' ' + category.create_join(root, join_category_roots, Arel::Nodes::OuterJoin).to_sql
  end

  def add_filter(field, operator, values, collection = self.filters)
    return if !self.available_filters.key?(field)
    values ||= []
    if values.is_a?(String)
      values = Array(values.force_encoding('UTF-8'))
    elsif values.is_a?(Array)
      values = values.flatten.collect { |x| x.force_encoding('UTF-8') if x.present? }.compact
    end
    collection[field] = { :operator => operator.to_s, :values => values }
  end

  def add_short_filter(field, expression, collection = self.filters)
    return unless expression && self.available_filters.has_key?(field)
    field_type = self.available_filters[field][:type]
    if field_type == :date_period && custom_date_period_filter?(expression)
      e = expression.split('|')

      if e.size == 1
        if e[0] =~ /\d{4}/ && (from_date = Date.parse(e[0]) rescue nil)
          self.add_filter(field, 'date_period_2', { :from => from_date, :to => from_date }, collection)
        else
          self.add_filter(field, 'date_period_1', self.get_date_range('1', e[0]).merge(:period => e[0]), collection)
        end
      elsif e[0] && e[0].include?('n_days')
        if e.size == 2
          days = e[1].to_i
          self.add_filter(field, 'date_period_1', { :period => e[0], :period_days => days }, collection)
        elsif e.size == 3
          self.add_filter(field, 'date_period_1', { :period => e[0], :period_days2 => e[1], :period_days => e[2] }, collection)
        end
      elsif e.size == 2
        self.add_filter(field, 'date_period_2', { :from => e[0], :to => e[1] }, collection)
      end
    else
      self.operators_by_filter_type[field_type].sort.reverse.detect do |operator|
        next unless expression =~ /^#{Regexp.escape(operator)}(.*)$/
        self.add_filter(field, operator, ($1.present? ? $1.split('|') : []), collection)
      end || self.add_filter(field, '=', expression.split('|'), collection)
    end
  end

  # Add multiple filters using +add_filter+
  def add_filters(fields, operators, values)
    if fields.is_a?(Array) && operators.is_a?(Hash) && (values.nil? || values.is_a?(Hash))
      fields.each do |field|
        self.add_filter(field, operators[field], values && values[field])
      end
    end
  end

  def has_filter?(field, filters = self.filters)
    filters and filters[field]
  end

  def filters_active?
    self.filters.any?
  end

  def type_for(field)
    self.available_filters[field][:type] if self.available_filters.has_key?(field)
  end

  def operator_for(field, filters = self.filters)
    self.has_filter?(field, filters) ? filters[field][:operator] : nil
  end

  def values_for(field, filters = self.filters)
    if self.has_filter?(field, filters)
      filters[field][:values] || []
    else
      nil
    end
  end

  def filtered_values_for(field, default_values, filters = self.filters)
    default_values ||= []
    values         = self.values_for(field, filters)
    operator       = self.operator_for(field, filters)

    return default_values unless values && operator

    values = personalized_field_value_for_statement(field, values)

    case operator
    when '='
      default_values.select { |default_value| values.include?(default_value[1].to_s) }
    when '!'
      default_values.select { |default_value| !values.include?(default_value[1].to_s) }
    when '!*'
      []
    when '*'
      default_values
    when 'o'
      if field == 'fixed_version_id'
        if project
          Version.values_for_select_with_project(project.shared_versions.open)
        else
          Version.values_for_select_with_project(Version.open.visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        end
      else
        field == 'status'
        IssueStatus.sorted.open.map { |s| [s.name, s.id.to_s] }
      end
    when 'c'
      if field == 'fixed_version_id'
        if project
          Version.values_for_select_with_project(project.shared_versions.closed)
        else
          Version.values_for_select_with_project(Version.closed.visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        end
      else
        field == 'status'
        IssueStatus.sorted.closed.map { |s| [s.name, s.id.to_s] }
      end
    when '>dd'
      if field == 'fixed_version_id'
        date_clause = date_clause(Version.table_name, 'effective_date', nil, (User.current.today - 1.day))
        if project
          Version.values_for_select_with_project(project.shared_versions.where(date_clause))
        else
          Version.values_for_select_with_project(Version.where(date_clause).visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        end
      end
    else
      default_values
    end
  end

  def value_for(field, index = 0, filters = self.filters)
    (self.values_for(field, filters) || [])[index]
  end

  def objects_for(field, klass = nil, filters = self.filters, **options)
    unless klass.is_a?(Class)
      assoc = field.gsub('_id', '').gsub('xproject', 'project')
      ref   = self.entity.reflect_on_association(assoc.to_sym)
      klass = ref.klass if ref
    end

    field_ids = values_for(field)
    if klass && field_ids
      return if klass <= ActsAsTaggableOn::Tag
      objects = []
      if klass <= Principal
        additional_options = User.additional_select_options
        additional_options.merge! Group.additional_select_options
        additional_options.merge!(options[:additional_select_options]) if options[:additional_select_options].present?

        (Array(field_ids) & additional_options.values).each do |v|
          objects << ENTITY_OBJECT.new(v, additional_options.key(v))
        end
      end
      objects.concat(klass.where(:id => field_ids).to_a)
    end
  end

  def object_for(field, klass = nil, index = 0, filters = self.filters)
    if objs = objects_for(field, klass, filters)
      objs.offset(index).limit(index + 1)[index]
    end
  end

  def objects_for_select(field, klass = nil)
    objs        = (objects_for(field, klass) || [])
    name_column = (klass.method_defined?(:name) ? :name : :to_s) if klass
    objs.map { |i| block_given? ? yield(i) : [i.send(name_column), i.id.to_s] }
  end

  def label_for(field)
    label = self.available_filters[field][:name] if self.available_filters.has_key?(field)
    label ||= queried_class.human_attribute_name(field, :default => field)
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    self.available_columns.select { |c| c.groupable }
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
    self.available_columns.inject({}) { |h, column|
      h[column.name.to_s] = column.sortable
      h
    }
  end

  def first_sumable_index
    inline_columns.index { |column| column.sumable? } || inline_columns.size
  end

  def sumable_columns
    available_columns.select { |c| c.sumable_top? || c.sumable_bottom? }.uniq
  end

  def sumable_columns?
    sumable_columns.any?
  end

  def sumable_columns_top
    available_columns.select { |c| c.sumable_top? }
  end

  def sumable_columns_bottom
    available_columns.select { |c| c.sumable_bottom? }
  end

  def sumable_columns_header
    available_columns.select { |c| c.sumable_header? }
  end

  def inline_columns
    @inline_columns ||= non_period_inline_columns + generated_period_columns
  end

  def non_period_inline_columns
    @non_period_inline_columns ||= columns.select { |c| c.inline? && c.visible? && c.permitted? }
  end

  def block_columns
    @block_columns ||= columns.select { |c| !c.inline? && c.visible? && c.permitted? }
  end

  def currency_columns
    @currency_columns ||= available_columns.select { |c| c.is_a?(EasyQueryCurrencyColumn) }
  end

  def currency_columns?
    self.currency_columns.any?
  end

  def display_show_avatars?
    user_columns.any?
  end

  def user_columns
    @user_columns ||= available_columns.select { |col| col.is_a?(EasyQueryCustomFieldColumn) ? col.user_lookup? : columns_with_me.include?(col.name.to_s + '_id') }
  end

  def date_columns
    @date_columns ||= available_columns.select { |c| c.date? && available_filters.key?(c.name.to_s) }
  end

  def groupable_geo_columns
    available_columns.select do |column|
      available_filters.key?(column.name.to_s) && # based on {date_columns} (dont know why)
          column.groupable &&
          column.is_a?(EasyQueryCustomFieldColumn) &&
          column.custom_field&.field_format == 'country_select'
    end
  end

  def generated_period_columns
    return [] unless period_columns?
    @generated_period_columns ||= 0.upto(number_of_periods_by_zoom - 1).map do |period_idx|
      period_columns.map do |period_column|
        period_column.generate(period_idx, self)
      end
    end.flatten
  end

  def period_columns
    @period_columns ||= columns.select { |c| c.is_a?(EasyQueryPeriodColumn) }
  end

  def period_columns?
    self.period_columns.any?
  end

  def get_generated_column(column_name, period_idx = 0)
    column = get_column(column_name.to_s)
    if column && column.is_a?(EasyQueryPeriodColumn)
      column.generate(period_idx, self)
    else
      column
    end
  end

  def chart_grouped_by_date_column?
    x_axis = Array.wrap(self.chart_settings['axis_x_column']).first.to_s
    return false if x_axis.blank?

    column = self.groupable_columns.detect { |c| c.groupable && c.name.to_s == x_axis }
    column && column.date?
  end

  def full_rows_columns
    @full_rows_columns ||= columns.select(&:full_rows_column?)
  end

  def full_rows_columns?
    self.full_rows_columns.size > 0
  end

  def available_inline_columns
    @available_inline_columns ||= available_columns.select { |c| c.inline? && !c.is_a?(EasyQueryPeriodColumn) }
  end

  def available_block_columns
    @available_block_columns ||= available_columns.select { |c| !c.inline? && !c.is_a?(EasyQueryPeriodColumn) }
  end

  def available_period_columns
    @available_period_columns ||= available_columns.select { |c| c.is_a?(EasyQueryPeriodColumn) }
  end

  def period_start_date
    self.period_settings.start_date
  end

  def period_end_date
    self.period_settings.end_date
  end

  def period_date_period
    self.period_settings[:period_date_period]
  end

  def period_date_period_type
    self.period_settings[:period_date_period_type] || '2'
  end

  def period_zoom
    self.period_settings.zoom
  end

  def period_start_date=(value)
    self.period_settings.start_date = value
  end

  def period_end_date=(value)
    self.period_settings.end_date = value
  end

  def period_date_period=(value)
    self.period_settings[:period_date_period] = value if value
  end

  def period_date_period_type=(value)
    self.period_settings[:period_date_period_type] = value if value
  end

  def switch_period_zoom_to(value)
    self.period_zoom       = value
    self.period_start_date = self.beginning_of_period_zoom(period_start_date)
    self.period_end_date   = self.end_of_period_zoom(period_start_date + period_zoom_shift(number_of_periods_by_zoom - 1))
  end

  def period_zoom=(value)
    self.period_settings.zoom = value
  end

  def all_periods
    self.period_settings.all_periods
  end

  def number_of_periods_by_zoom
    self.period_settings.number_of_periods_by_zoom
  end

  def beginning_of_period_zoom(date = nil, zoom = nil)
    self.period_settings.beginning_of_period(date, zoom)
  end

  def end_of_period_zoom(date = nil, zoom = nil)
    self.period_settings.end_of_period(date, zoom)
  end

  def range_of_period_zoom(date = nil, zoom = nil)
    period_settings.range_of_period(date, zoom)
  end

  def period_zoom_shift(idx)
    shift = (period_start_date - beginning_of_period_zoom(period_start_date))
    if idx > 0
      self.period_settings.zoom_shift(idx) - shift.days
    else
      self.period_settings.zoom_shift(idx)
    end
  end

  def current_period_start_date(idx)
    period_start_date + period_zoom_shift(idx)
  end

  def current_period_end_date(idx)
    [end_of_period_zoom(current_period_start_date(idx)), period_end_date].min
  end

  def previous_period_start_date
    period_start_date - period_zoom_shift(number_of_periods_by_zoom)
  end

  def group_by
    Array(super)
  end

  def group_by=(value)
    clear_column_sums_cache
    if value.is_a?(Array)
      value.uniq!
      value.reject!(&:blank?)
    end
    super value.presence
  end

  def outputs
    res = super
    if res.blank?
      res = get_default_values_from_easy_settings('default_outputs') || []
    end
    Array(res)
  end

  def support_output?(output)
    available_outputs.include?(output.to_s)
  end

  def self.global_project_context?
    true
  end

  def table_support?
    true
  end

  def report_support?
    true
  end

  alias_method :list_support?, :table_support?

  def self.list_support?
    true
  end

  def self.report_support?
    true
  end

  def self.tiles_support?
    true
  end

  def self.chart_support?
    false
  end

  def tiles_support?
    self.class.tiles_support?
  end

  def chart_support?
    self.class.chart_support?
  end

  def calendar_support?
    false
  end

  def self.no_params_url_support?
    true
  end

  def available_outputs
    EasyExtensions::EasyQueryHelpers::EasyQueryPresenter.new(self).available_outputs.map { |o| o.to_s }
  end

  def output=(output)
    ary = Array(output)
    ary.push('list') if ary.delete('table')
    self.outputs = if ary.length > 1
                     ary & self.available_outputs
                   else
                     output_available?(ary.first) ? ary : []
                   end
  end

  def output_available?(output_name)
    EasyExtensions::EasyQueryHelpers::EasyQueryOutput.output_available?(self, output_name)
  end

  def no_output?
    available_outputs.blank?
  end

  def get_column(name)
    self.available_columns.detect { |c| c.name.to_s == name }
  end

  def columns
    columns = if @disable_columns
                []
              elsif self.has_default_columns?
                def_columns = []
                self.default_list_columns.each { |cname| def_columns << self.get_column(cname) }
                if self.display_project_column_if_project_missing && self.project.nil? && (project_column = self.available_columns.detect { |c| c.name == :project })
                  def_columns.unshift project_column unless def_columns.include?(project_column)
                end
                def_columns.compact!
                def_columns.uniq!
                def_columns
              else
                # preserve the column_names order
                self.column_names.collect do |name|
                  self.available_columns.detect { |col| col.name == name }
                end.compact
              end

    return columns
  end

  def column_names=(names)
    clear_column_sums_cache
    @used_column_names = nil
    if names
      names = names.select { |n| n.is_a?(Symbol) || !n.blank? }
      names = names.collect { |n| n.is_a?(Symbol) ? n : n.to_sym }
    end
    write_attribute(:column_names, names)
  end

  def has_column?(column)
    used_column_names.include?(column.is_a?(EasyQueryColumn) ? column.name : column)
  end

  def used_column_names
    @used_column_names ||= (self.has_default_columns? ? self.default_list_columns.map(&:to_sym) : self.column_names) || []
  end

  def has_custom_field_column?
    columns.any? { |column| column.is_a? EasyQueryCustomFieldColumn }
  end

  def has_default_columns?
    self.column_names.blank?
  end

  def list_columns_changed?
    return self.default_list_columns.collect(&:to_sym) != self.columns.collect(&:name)
  end

  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.collect { |k| arg[k] }
    end

    if arg
      c = arg.select { |k, o| !k.to_s.blank? }.slice(0, 3).collect { |k, o| [k.to_s, (o == 'desc' || o == false) ? 'desc' : 'asc'] }
    end

    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    super || []
  end

  def default_sort_criteria
    get_default_values_from_easy_settings(DEFAULT_SORTING_SUFFIX) || Array.new
  end

  def sort_criteria_init
    if sort_criteria.empty?
      default_sort_criteria
    else
      sort_criteria
    end
  end

  def sort_criteria_key(arg)
    self.sort_criteria && self.sort_criteria[arg] && self.sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    self.sort_criteria && self.sort_criteria[arg] && self.sort_criteria[arg].last
  end

  def sort_criteria_order_for(key)
    sort_criteria.detect { |k, order| key.to_s == k }.try(:last)
  end

  def sort_criteria_to_sql_order(criterias = sort_criteria)
    # criterias.select { |field_name, asc_desc| !!sortable_columns_sql[field_name] }.collect { |field_name, asc_desc| (sortable_columns_sql[field_name].is_a?(Array) ? sortable_columns_sql[field_name].join(" #{asc_desc}, ") : sortable_columns_sql[field_name]) + ' ' + (asc_desc || 'asc') }.join(', ')

    criterias        = criterias.to_h
    sort_columns     = criterias.dup
    sortable_columns = []
    self.available_columns.each do |col|
      next if !col.sortable?
      col_name = col.name.to_s
      if criterias.key?(col_name)
        sort_columns[col_name] = col.sort_order_sql(self, criterias[col.name.to_s])
        sortable_columns << col_name
      end
    end
    sort_columns.select! { |col, _| sortable_columns.include?(col) }
    Arel.sql(sort_columns.values.join(', '))
  end

  def load_groups_opened=(value)
    self.groups_opened = value
  end

  def load_groups_opened
    self.groups_opened
  end

  def load_groups_opened?
    self.groups_opened?
  end

  def add_additional_statement(additional_where)
    if self.additional_statement.blank?
      self.additional_statement = additional_where
    else
      self.additional_statement += ' AND ' + additional_where
    end
  end

  def add_additional_scope(scope)
    scope = self.entity.where(scope) unless [ActiveRecord::Relation, Proc].any?{ |type| scope.is_a?(type) }

    if additional_scope
      self.additional_scope = self.additional_scope.merge(scope)
    else
      self.additional_scope = scope
    end
  end

  def add_statement_limitation_to_ids(ids)
    entity_ids = Array.wrap(ids)
    if entity_ids.present?
      additional_where = "#{self.entity.table_name}.id IN (#{entity_ids.join(',')})"
      add_additional_statement(additional_where)
    end
  end

  def validate_values(field, operator, values, raise_exception: false)
    @values_validator ||= EasyExtensions::EasyQueryHelpers::ValuesValidator.new(self)
    is_valid          = @values_validator.valid?(field, operator, values)

    if raise_exception && !is_valid
      raise StatementInvalid, "Cannot validate field: '#{field}', operator: '#{operator}', values: '#{values}'"
    else
      is_valid
    end
  end

  def filter_statement(field, operator, value, validate: false)
    if statement_skip_fields.include?(field) || !available_filters.key?(field)
      return
    end

    if !hidden_values_by_operator.include?(operator) && value.blank?
      return
    end

    value = if value.is_a?(Integer)
      value.to_s
    elsif value == nil
      ''
    else
      value.dup
    end
    value = personalized_field_value_for_statement(field, value)

    # It will raise an exception so there is no need to check return value
    validate && validate_values(field, operator, value, raise_exception: true)

    custom_sql = get_custom_sql_for_field(field, operator, value)
    if custom_sql.present?
      return custom_sql
    end

    if field =~ /cf_(\d+)$/
      return sql_for_custom_field(field, operator, value, $1)

    elsif respond_to?(met = sql_for_field_method_name(field))
      return send(met, field, operator, value)
    end

    db_table, db_field = db_table_field(field)
    value              = get_enum_value(field, value)
    sql                = sql_for_field(field, operator, value, db_table, db_field)

    if sql.present?
      '(' + sql + ')'
    end
  end

  def statement(filters = self.filters)
    filters_clauses = []

    if query_string.present? && EasySetting.value('query_string_enabled')
      # TODO: kill an expensive query
      begin
        tree = EasyExtensions::QueryString::Parser.new.parse(query_string)
        sql  = EasyExtensions::QueryString::Transform.new.apply(tree, easy_query: self)
        filters_clauses << sql

      rescue Parslet::ParseFailed, StatementInvalid
        # To avoid errors duplication
        errors.add(:query_string) if !errors.added?(:query_string)
        return '1=0'
      end
    end

    sql = add_statement_sql_before_filters
    filters_clauses << sql if sql.present?

    filters.each_key do |field|
      value    = values_for(field, filters)
      operator = operator_for(field, filters)

      clause = filter_statement(field, operator, value)
      filters_clauses << clause if clause
    end if filters

    if grouped?
      # Excludes results for which the grouped custom fields are not visible
      filters_clauses.concat(group_by_column.custom_fields_visibility_by_project_condition)
    end

    filters_clauses << additional_statement if additional_statement.present?
    filters_clauses.reject!(&:blank?)
    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def personalized_field_value_for_statement(field, v)
    if columns_with_me.include?(field)
      if v.is_a?(Array)
        if User.current.logged?
          if v.delete('me_and_my_groups')
            v.concat(User.current.group_ids.map(&:to_s))
            v.push(User.current.id.to_s)
          elsif v.delete('me')
            v.push(User.current.id.to_s)
          end
        end
        v.push('0') if v.empty?
      elsif v == 'me'
        v = User.current.id.to_s
      elsif v == 'me_and_my_groups'
        v = User.current.group_ids.map(&:to_s)
        v.push(User.current.id.to_s)
      end
    end

    if ['project_id', 'xproject_id'].include?(field)
      if v.is_a?(Array)
        if v.delete('mine')
          v.concat(User.current.memberships.pluck(:project_id).map(&:to_s))
        end

        if v.delete('current') && project
          v.push project.id.to_s
        end
      else
        if v == 'mine'
          v = User.current.memberships.pluck(:project_id).map(&:to_s)
        end

        if v == 'current' && project
          v = project.id.to_s
        end
      end
    end
    v
  end

  def having_statement(group_filters = self.group_filters)
    # filters clauses
    filters_clauses = []

    group_filters.each_key do |field|
      next if field != :count && !having_filter?(field)
      v         = self.values_for(field, group_filters)
      operator  = self.operator_for(field, group_filters)
      operation = group_filters[field][:operation]
      next if !self.hidden_values_by_operator.include?(operator) && v.blank?

      value = v.nil? ? '' : v.dup

      if field.to_s =~ /cf_(\d+)$/
        # filters_clauses << self.sql_for_custom_field(field, operator, v, $1)
      else
        is_custom_filter = false
        if field == :count
          filter_type        = :integer
          full_db_field_name = "COUNT(*)"
        else
          filter_type        = type_for(field)
          db_table, db_field = db_table_field(field)
          full_db_field_name = "#{operation}(#{db_table}.#{db_field})"
          if filter_type == :currency && easy_currency_code
            full_db_field_name + '_' + easy_currency_code
          end
        end
        case operator
        when '='
          case filter_type
          when :integer
            int_values = value.first.to_s.scan(/[+-]?\d+/).map(&:to_i).join(',')
            if int_values.present?
              if is_custom_filter
                sql = "(#{full_db_field_name} <> '' AND CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(30,0)) IN (#{int_values}))"
              else
                sql = "#{full_db_field_name} IN (#{int_values})"
              end
            else
              sql = '1=0'
            end
          when :float, :currency
            float_val = value.first.to_f
            if is_custom_filter
              sql = "(#{full_db_field_name} <> '' AND CAST(CASE #{db_table}.#{db_field} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(30,3)) BETWEEN #{float_val - 1e-5} AND #{float_val + 1e-5})"
            else
              sql = "#{full_db_field_name} BETWEEN #{float_val - 1e-5} AND #{float_val + 1e-5}"
            end
          end
        when '>='
          if is_custom_filter
            sql = "(#{full_db_field_name} <> '' AND CAST(#{full_db_field_name} AS decimal(60,3)) >= #{value.first.to_f})"
          else
            sql = "#{full_db_field_name} >= #{value.first.to_f}"
          end
        when '<='
          if is_custom_filter
            sql = "(#{full_db_field_name} <> '' AND CAST(#{full_db_field_name} AS decimal(60,3)) <= #{value.first.to_f})"
          else
            sql = "#{full_db_field_name} <= #{value.first.to_f}"
          end
        when '><'
          if is_custom_filter
            sql = "(#{full_db_field_name} <> '' AND CAST(#{full_db_field_name} AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f})"
          else
            sql = "#{full_db_field_name} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
          end
        end
        filters_clauses << ('(' + sql + ')') if sql.present?
      end

    end if group_filters

    filters_clauses.reject!(&:blank?)
    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def entity_scope
    if !@entity_scope.nil?
      @entity_scope
    elsif self.entity.respond_to?(:visible)
      self.entity.visible
    else
      self.entity
    end
  end

  def set_entity_scope(entity_or_entity_scope, reference_collection = nil)
    return if entity_or_entity_scope.nil?

    if entity_or_entity_scope.is_a?(ActiveRecord::Base)
      return if reference_collection.nil?

      @entity_scope = entity_or_entity_scope.send(reference_collection.to_sym)
    else
      @entity_scope = entity_or_entity_scope
    end
    self.filters = {}
    @entity_scope
  end

  # Returns the sum of _column_ or column
  # TODO: znovu, lepe!!!
  def entity_sum(column, options = {})
    # I know this is a terrible solution but try find word "sum"
    # in all easy queries and all queries outputs
    case aggregate_by.to_s
    when 'sum'
      return entities_sum(column, options)
    when 'average'
      return entities_average(column, options)
    end

    c      = column
    column = columns.detect { |c| c.name.to_sym == column } if column.is_a?(Symbol)

    unless column.is_a?(EasyEntityAttribute)
      scope = merge_scope(self.new_entity_scope, options)
      scope = limit_group_ids(scope, options)
      return scope.sum(column || c)
    end

    if column.sumable_sql == false && options[:entities]
      query_entities = options[:entities].is_a?(Array) ? options[:entities] : entities
      return summarize_column(column, query_entities, nil, options)
    end
    if column.sumable_sql == false && column.visible? && options[:group]
      unless @grouped_scope
        additional_joins = column.additional_joins(entity, :array) + joins_for_order_statement(options[:group].to_s, :array, false)
        additional_joins.concat(self.group_by_column.additional_joins(entity, :array, false)) if self.grouped? && self.group_by_column.assoc
        options[:joins] = Array(options[:joins]) + additional_joins
        @grouped_scope  = merge_scope(self.new_entity_scope, options.merge({ group: nil }))
      end
      results = {}
      @grouped_scope.to_a.each do |e|
        g        = group_by_column.value(e)
        group_id = (g.is_a?(ActiveRecord::Base) ? g.id : g) || ''
        results[group_id] ? results[group_id] += column.value(e) || 0 : results[group_id] = column.value(e)
      end
      return results
    end

    additional_joins = column.additional_joins(entity, :array) + joins_for_order_statement(options[:group].to_s, :array, false)
    additional_joins.concat(self.group_by_column.additional_joins(entity, :array, false)) if self.grouped?
    options[:joins]    = Array(options[:joins]) + additional_joins
    column_name        = column.sumable_sql || column.name

    options[:includes] = Array(options[:includes]).concat(Array(column.includes)).uniq if column.includes.is_a?(Array) || column.includes.is_a?(Symbol)

    if column.sumable_options.distinct_columns?
      select_group    = []
      group_aliases   = []
      select_scope    = entity_scope.all
      options[:group] = Array.wrap(options[:group])
      options[:group].each do |group_field|
        group_aliases << select_scope.send(:column_alias_for, group_field)
        select_group << group_field.to_s + ' AS ' + group_aliases.last
      end

      options[:group] += column.sumable_options.distinct_columns.collect { |dc| /\./.match?(dc) ? dc : "#{entity.quoted_table_name}.#{dc}" }
      scope           = merge_scope(self.new_entity_scope, options)
      scope           = scope.select('MAX(' + column_name.to_s + ') AS result')
      scope           = scope.select(select_group) if select_group.any?
      scope           = limit_group_ids(scope, options)

      res = entity.base_class.from("(#{scope_for_calculations(scope).to_sql}) AS DT1").group(group_aliases.join(', ')).pluck(Arel.sql((group_aliases + ['SUM(result) AS result']).join(', ')))

      if select_group.empty?
        result = res.first || 0.0
        result = result.round(2) if result.is_a?(Float) # fix approximation errors on mysql
      else
        result       = {}
        groups_count = group_aliases.count

        if Redmine::Database.mysql?
          boolean_keys    = entity.columns_hash.select { |_, column_options| column_options.type == :boolean }.keys
          boolean_indexes = []
          options[:group].each_with_index do |group, i|
            if boolean_keys.detect { |key| group.include?(key) }
              boolean_indexes << i
            end
          end
        end

        res.each do |row|
          keys = row.first(groups_count)
          if boolean_indexes
            boolean_indexes.each { |i| keys[i] = keys[i].to_s.to_boolean }
          end
          keys         = keys.first unless groups_count > 1
          result[keys] = row.last || 0.0
          result[keys] = result[keys].round(2) if result[keys].is_a?(Float) # fix approximation errors on mysql
        end
      end

      result
    else
      scope = merge_scope(self.new_entity_scope, options)
      scope = limit_group_ids(scope, options)
      scope.sum(column_name)
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the issue count
  def entity_count(options = {})
    new_options = options.except(:limit, :order)
    if self.use_free_search
      self.search_freetext_count(self.free_search_tokens, new_options)
    else
      new_options[:joins] = Array(new_options[:joins]) + (new_options[:group] ? self.joins_for_order_statement((new_options[:group]).to_s, :array, false) : [])
      scope               = merge_scope(self.new_entity_scope(nil, without_columns: true), new_options)
      scope               = limit_group_ids(scope, new_options)
      scope.except(:select).count(:all)
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns group count
  def groups_count(options = {})
    return 0 unless self.grouped?
    # options = options.dup # only_group_order is propagated so result from query.prepare_result is not sorted
    # options[:only_group_order] = true #postgres complaining and wee dont need it
    # group_by = self.group_by_statement
    # options[:joins] = Array(options[:joins]) + self.group_by_column.additional_joins(entity, :array, false) + joins_for_order_statement(group_by, :array, false)
    # options[:joins].uniq!
    # scope = create_entity_scope(options.merge({:skip_order => true})).group(group_by)
    entity_count_by_group(options).keys.count
  end

  # Returns count of entities on the list action
  # returns groups_count if query is grouped and entity_count otherwise
  def entity_count_for_list(options = {})
    if self.grouped?
      return groups_count(options)
    else
      return entity_count(options)
    end
  end

  # Returns the issue count by group or nil if query is not grouped
  def entity_count_by_group(options = {})
    r = nil
    if self.grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = self.entity_count({ :group => self.group_by_statements, :includes => self.default_find_include }.merge(options))
      rescue
        r = { nil => self.entity_count }
      end
      if c = self.group_by_column
        r = r.keys.each_with_object({}) { |k, h| h[c.sanitize_name(k)] = r[k] }
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def entity_sum_by_group(column, options = {})
    r = Hash.new
    if grouped?
      merge_options(options, group_additional_options)
      r = entity_sum(column, { :group => self.group_by_statements }.merge(options))
    end

    return r
  end

  def new_entity_scope(scope = nil, options = {})
    scope ||= self.entity_scope.where(self.statement)
    scope = scope.merge(additional_scope) if additional_scope

    includes = Array.wrap(self.default_find_include).dup
    preload  = Array.wrap(self.default_find_preload).dup
    joins    = Array.wrap(self.default_find_joins).dup
    self.filters.each_key do |filter|
      f = available_filters[filter]
      if f && f[:includes]
        includes.concat(Array.wrap(f[:includes]))
      end
      if f && f[:joins]
        joins.concat(Array.wrap(f[:joins]))
      end
    end
    unless options[:without_columns]
      self.columns.each do |c|
        includes.concat(Array.wrap(c.includes)) if c.includes
        joins.concat(Array.wrap(c.joins)) if c.joins
        preload.concat(Array.wrap(c.preload)) if c.preload
      end
    end
    if self.grouped? && (c = self.group_by_column)
      includes.concat(c.includes)
      joins.concat(c.joins)
      preload.concat(c.preload)
    end

    possible_columns = Array.new
    possible_columns.concat(self.group_by_column.collect { |col| col.name.to_sym }) if self.grouped?
    possible_columns.concat(self.sort_criteria.collect { |s| s.first.to_sym })

    unless options[:without_columns]
      self.available_columns.each do |col|
        if col.includes && possible_columns.include?(col.name.to_sym)
          includes.concat(col.includes)
        end
      end
    end

    includes.uniq!; joins.uniq!; preload.uniq!
    scope = scope.eager_load(includes) if includes.any?
    scope.joins(joins).preload(preload)
  end

  def create_entity_scope(options = {})
    if options[:skip_order]
      # PostgreSQL hack
      # remove order wher it is not needed
      #
      # FIXME: NEED KEEP order_option for joins_for_order_statement (for cf)
      #
      scope_options = options.except(:order)
    else
      order_joins = []
      unless options[:skip_group_order]
        group_order = self.group_by_sort_order
      end
      if options[:only_group_order]
        order_option = group_order
      else
        order_option = Array(options[:order] || self.sort_criteria_to_sql_order).reject { |s| s.blank? }
        order_joins  = joins_for_order_statement((order_option + Array(group_by_sort_order)).join(', '), :array)
        order_option.unshift(group_order) if group_order.present?
      end
      order_option  = nil if order_option.blank?
      scope_options = options.merge({ :order => order_option, :joins => Array(options[:joins]) + order_joins })
    end

    scope = options[:only_group_order] ? with_sort_criteria([]) { self.new_entity_scope } : self.new_entity_scope
    scope = merge_scope(scope, scope_options)
    scope
  end

  # Returns the issues
  # Valid options are :order, :offset, :limit, :include, :conditions
  def entities(options = {})
    if self.use_free_search
      self.search_freetext(self.free_search_tokens, options).to_a
    else
      create_entity_scope(options.merge(skip_group_order: true)).to_a
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def build_calendar(options = {})
    raise "#{self.class.name} does not have calendar support" unless self.calendar_support?
    user             = options[:user] || User.current
    options[:period] ||= settings['period']
    start_date       = begin
      ; options[:start_date].to_date;
    rescue;
    end
    if start_date
      filters.delete(calendar_options[:start_date_filter])
      filters.delete(calendar_options[:end_date_filter])
    else
      start_date = user.today
    end

    calendar = self.calendar_class.new(start_date, current_language, (options[:period].blank? ? :week : options[:period].to_sym))
    #{ :limit => (row_limit > 0 ? row_limit : nil) }
    if calendar_options[:start_date_filter] && filters[calendar_options[:start_date_filter]].blank? &&
        calendar_options[:end_date_filter] && filters[calendar_options[:end_date_filter]].blank?
      startdt, enddt    = case calendar.period
                          when :month
                            [start_date.beginning_of_month, start_date.end_of_month]
                          else
                            [calendar.startdt, calendar.enddt]
                          end
      self.entity_scope = self.entity_scope.
          where(["((#{entity.table_name}.#{calendar_options[:start_date_filter]} BETWEEN ? AND ?)
        OR (#{entity.table_name}.#{calendar_options[:end_date_filter]} BETWEEN ? AND ?))",
                 startdt, enddt.end_of_day, startdt, enddt.end_of_day])
    end
    calendar.events = entities(limit: options[:limit])
    calendar
  end

  def entities_ids(options = {})
    scope = create_entity_scope(options.merge(skip_group_order: true))
    Array(scope.pluck(:id))
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def search_freetext_count(tokens, options = {})
    options[:all_words] = true unless options.key?(:all_words)
    options[:limit]     = 25 unless options.key?(:limit)
    tokens              = [] << tokens unless tokens.is_a?(Array)

    token_clauses = statement_for_searching
    sql           = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

    scope = create_entity_scope(options.merge(skip_order: true))
    if tokens.present? && token_clauses.present?
      scope = scope.where(search_freetext_where_conditions(sql, tokens, token_clauses))
    end
    scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def search_freetext(tokens, options = {})
    options[:all_words] = true unless options.key?(:all_words)
    tokens              = [] << tokens unless tokens.is_a?(Array)

    token_clauses = statement_for_searching
    sql           = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

    scope = create_entity_scope(options.merge(skip_group_order: true))
    if tokens.present? && token_clauses.present?
      scope = scope.where(search_freetext_where_conditions(sql, tokens, token_clauses))
    end
    scope.limit(options[:limit] || 25)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def search_freetext_where_conditions(sql, tokens, token_clauses)
    [sql, * (tokens.collect { |i| "%#{i}%" } * token_clauses.size).sort]
  end

  def additional_group_attributes(group, attributes, options = {})
  end

  def groups(options = {})
    return unless self.grouped?
    group_by    = self.group_by_statement
    group_by    += self.additional_group_by_for_sort
    group_scope = create_entity_scope(options.merge({ :only_group_order => true, :without_columns => true })).group(group_by)

    group_col = self.group_by_column
    joins     = joins_for_order_statement(self.group_by_sort_order.join(', '), :array, false)
    if group_col.custom?
      joins.concat(self.group_by_column.additional_joins(self.entity, :array, false))
    end
    group_scope = group_scope.joins(joins.uniq)
    group_scope = group_scope.having(having_statement)

    group_ids = group_scope.pluck(Arel.sql("#{self.group_by_statement}, MIN(#{self.entity.table_name}.id)"))

    scope = self.entity
    scope = scope.preload(default_groups_preload)
    scope = scope.preload(group_col.preload) if group_col.preload
    scope = scope.eager_load(group_col.includes) if group_col.includes && group_col.includes.any?

    entities_per_group = scope.find(group_ids.collect(&:last)).inject({}) { |mem, e| mem[e.id] = e; mem }

    limited_ids  = group_ids.map { |x| x.first(x.size - 1) }
    counts       = self.entity_count_by_group(group_ids: limited_ids)
    global_count = self.entity_count

    groups = {}
    group_ids.each do |group_vals|
      entity_id = group_vals.pop
      entity    = entities_per_group[entity_id]
      group     = group_col.sanitize_name(group_vals)
      name      = group_col.value(entity, period: group_by_period, group: Array.wrap(group))

      count = counts[group] || counts[name]

      sum        = summarize_entities(nil, group_vals, group_ids: limited_ids)
      attributes = { :name => name, :sums => sum, :count => count, :entity => entity }
      if options[:include_entities]
        if open_category?(group)
          attributes[:entities] = self.entities_for_group(group, options).to_a
        else
          attributes[:entities] = []
        end
      end
      groups[group] = attributes

      additional_group_attributes(group, attributes, entity: entity, global_count: global_count)
    end

    groups
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def group_by_period
    return nil unless grouped? && group_by_column.date?
    self.period_zoom.to_sym
  end

  def open_category?(group)
    open_categories_ids.nil? || open_categories_ids.include?((group.present? ? (group.try(:id) || group) : 'nil').to_s)
  end

  def group_condition(column, value)
    field_name = column.name.to_s
    if /cf_(\d+)$/.match?(field_name)
      cf_field_name = column.assoc ? "#{column.assoc}_#{column.entity_attribute_name.to_s}" : field_name
      self.sql_for_custom_field_without_filter(cf_field_name, '=', value.to_s, column.custom_field)
    elsif respond_to?(method = sql_for_field_method_name(field_name))
      # specific statement
      send(method, field_name, '=', value.to_s)
    else
      if !entity.column_names.include?(field_name)
        if column.groupable.is_a?(String)
          field_name = column.groupable
        elsif assoc = entity.reflect_on_association(field_name)
          field_name = assoc.foreign_key
        end
      end
      if /^(\w+.)?\w+$/.match?(field_name)
        db_table, db_field = db_table_field(field_name)
      else
        db_table = nil
        db_field = field_name
      end

      if column.is_a?(EasyQueryDateColumn)
        date = value.to_date rescue nil
        if date.nil?
          get_date_clause('date_period_1', { period: :is_null }, db_table, db_field, nil)
        else
          get_date_clause('date_period_2', group_date_period_range(column.name.to_s, date), db_table, db_field, nil)
        end
      else
        returned_sql_for_field = self.sql_for_field(field_name, value.blank? ? '!*' : '=', value.to_s, db_table, db_field)
        ('(' + returned_sql_for_field + ')') if returned_sql_for_field.present?
      end
    end
  end

  def group_entities_scope(group, options = {})
    group         = Array.wrap(group)
    conditions    = []
    joins         = []
    saved_filters = self.filters.dup

    self.group_by_column.each_with_index do |col, i|
      field_name = col.name.to_s
      if col.assoc && col.assoc_type == :has_many && available_filters.key?("#{col.assoc}.id")
        filter = "#{col.assoc}.id"
      elsif available_filters.key?(field_name)
        filter = field_name
      else
        field_with_id = field_name + '_id'
        filter        = field_with_id if available_filters.key?(field_with_id)
      end

      if filter
        if type_for(filter) == :boolean
          case group[i].to_s
          when 'true'
            group[i] = '1'
          when 'false'
            group[i] = '0'
          end
        end
        if type_for(filter) == :date_period
          date = group[i].to_date rescue nil
          if date.nil?
            self.add_filter(filter, 'date_period_1', { period: :is_null })
          else
            self.add_filter(filter, 'date_period_2', group_date_period_range(filter, date))
          end
        else
          self.add_filter(filter, group[i].blank? ? '!*' : '=', group[i].to_s)
        end
      else
        condition = group_condition(col, group[i])
        conditions << condition if condition.present?
        joins.concat(col.additional_joins(self.entity, :array, true))
      end
    end
    scope        = create_entity_scope(options.merge(skip_group_order: true))
    self.filters = saved_filters

    scope        = scope.joins(joins) if joins.any?

    scope.where(conditions.join(' AND '))
  end

  def entities_for_group(group, options = {})
    group_entities_scope(group, options).to_a
  end

  def count_group_entities(group, options = {})
    group_entities_scope(group, options.except(:limit, :offset)).count
  end

  def prepare_html_result(options = {})
    return entities_for_group(loading_group, options) if loading_group

    if self.grouped?
      return groups(options)
    else
      return entities(options)
    end
  end

  def prepare_export_result(options = {})
    if self.grouped?
      return groups(options.merge(:include_entities => true))
    else
      entities = entities(options)
      return { nil => { :entities => entities, :sums => summarize_entities(entities) } }
    end
  end

  def operators_for_select(filter_type)
    self.operators_by_filter_type[filter_type].collect { |o| [l(self.operators[o]), o] }
  end

  def from_params(params)
    return if params.nil?
    params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)

    params = expand_params(params)

    if params['set_filter'] == '1'
      self.filters = {}
      # TODO is needed? why? it fails to save a group_by set by attribute
      # self.group_by = ''
    else
      self.filters  = self.default_filter
      self.group_by = self.default_group_by
      self.outputs  = get_default_values_from_easy_settings('default_outputs') || self.outputs
    end

    if params['fields'] && params['fields'].is_a?(Array)
      params['values']    ||= {}
      params['operators'] ||= {}
      params['fields'].each do |field|
        self.add_filter(field, params['operators'][field], params['values'][field])
      end
    elsif params['f'].is_a?(Hash)
      params['f'].each do |field, expression|
        self.add_short_filter(field, expression)
      end
    else
      self.available_filters.each do |(key, _values)|
        self.add_short_filter(key, params[key]) if params[key]
      end
    end

    self.query_string = params['query_string'].presence

    # Filters which override previous or add new ones
    # Used for example as easy page global filters
    additional_filters = params.fetch('additional_filters', {})
    additional_filters.each do |field, value|
      add_short_filter(field, value)
    end

    self.add_custom_formatting_from_params(params) if EasySetting.value('show_easy_custom_formatting')
    self.group_by           = params['group_by'] if params['group_by'].present?
    self.show_sum_row       = params['show_sum_row'].present? ? params['show_sum_row'].try(:to_boolean) : default_show_sum_row
    self.load_groups_opened = params['load_groups_opened'].present? ? params['load_groups_opened'].try(:to_boolean) : default_load_groups_opened
    self.show_avatars       = params['show_avatars'].present? ? params['show_avatars'].try(:to_boolean) : default_show_avatars
    self.daily_snapshot     = params['daily_snapshot'].present? ? params['daily_snapshot'].try(:to_boolean) : default_daily_snapshot

    if params['outputs'].is_a?(Array)
      output_ary = params['outputs']
      output_ary.push('list') if output_ary.delete('table')
      self.outputs = (output_ary.uniq & self.available_outputs)
    elsif params['output']
      self.output = params['output']
    end

    self.calculation_formula = params['calculation_formula'] if params['calculation_formula'].present?
    self.easy_currency_code  = params['easy_currency_code'] if params['easy_currency_code'].present?

    if params['column_names'] && params['column_names'].is_a?(Array)
      if params['column_names'].first && params['column_names'].first.include?(',')
        self.column_names = params['column_names'].first.split(',')
      else
        self.column_names = params['column_names']
      end
    end

    if params['settings'] && params['settings'].is_a?(Hash)
      if self.settings.is_a?(Hash)
        self.settings = self.settings.merge(params['settings']).to_hash
      else
        self.settings = params['settings'].dup.to_hash
      end
    end

    if params['chart_settings'] && params['chart_settings'].is_a?(Hash)
      if self.chart_settings.is_a?(Hash)
        self.chart_settings.merge!(params['chart_settings'])
      else
        self.chart_settings = params['chart_settings'].dup
      end
    end
    self.chart_settings['axis_x_column'] = self.group_by_column.first.name.to_s if self.grouped? && self.chart_settings['axis_x_column'].blank?
    self.chart_settings['period_column'] = self.chart_settings['axis_x_column'] if chart_grouped_by_date_column?

    self.set_additional_params(params)
    self.set_sort_params(params)
    self.set_referenced_collection_params(params)

    if params['easy_query_q'].present?
      process_term params['easy_query_q']
    end
  end

  def process_term(term)
    self.use_free_search      = true
    self.free_search_question = term
    self.free_search_question.strip!

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    self.free_search_tokens = self.free_search_question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') }
    # tokens must be at least 2 characters long
    self.free_search_tokens = self.free_search_tokens.uniq.select { |w| w.length > 1 }
    self.free_search_tokens.slice! 5..-1 if self.free_search_tokens.size > 5
  end

  def set_sort_params(params)
    self.sort_criteria = params['sort_criteria'] if params['sort_criteria'].present? && params['query_type'] != '1'
    self.sort_criteria = Array(set_sort_helper(params['sort']))
  end

  def set_sort_helper(sort = nil)
    @sort_helper = Redmine::SortCriteria.new(sort.presence || self.sort_criteria_init)
  end

  def easy_currency_code=(value)
    if EasyCurrency.activated.where(iso_code: value).exists?
      super
    end
  end

  def set_additional_params(params)
    params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)

    self.period_date_period      = params['period_date_period'].present? ? params['period_date_period'] : (self.period_settings[:period_date_period] || default_period_date_period)
    self.period_date_period_type = params['period_date_period_type'].present? ? params['period_date_period_type'] : (self.period_settings[:period_date_period_type] || default_period_date_period_type)
    self.period_zoom             = params['period_zoom'].present? ? params['period_zoom'] : (self.period_settings[:period_zoom] || default_period_zoom)
    filter                       = get_period_filter if self.chart_settings['period_column']
    if params['period_start_date'].blank? && params['period_end_date'].blank? && self.chart_settings['period_column'] != self.chart_settings['axis_x_column']
      if params['period_date_from_calendar'].present?
        self.period_settings.set_current_period(params['period_date_from_calendar'].to_s.to_date)
      elsif outputs.include?('chart')
        self.period_settings.set_current_period
      end
    elsif params['period_date_from_calendar']
      params['period_start_date'] = params['period_date_from_calendar']
    end

    if filter && params['period_start_date'].blank? && params['period_end_date'].blank?
      period_range = self.get_date_range(filter[:operator].gsub(/^date_period_(\d+)/, '\1'), filter[:values][:period], filter[:values][:from], filter[:values][:to], 0, filter[:values][:period_days2], filter[:values][:period_days])
    else
      period_range = self.get_date_range(self.period_date_period_type, self.period_date_period, params['period_start_date'], params['period_end_date'])
    end

    self.period_start_date  = period_range[:from] || default_period_start_date
    self.period_end_date    = period_range[:to] || default_period_end_date
    self.easy_currency_code = params['easy_currency_code'] if params['easy_currency_code'].present?
    if params['switch_period_zoom'].present?
      self.switch_period_zoom_to params['switch_period_zoom']
    end

    if params['easy_query'] && params['easy_query']['columns_to_export'] == 'all'
      self.column_names = available_columns.collect { |col| col.name.to_s }
    end

    self.dont_use_project = params['dont_use_project'].to_s.to_boolean if params['dont_use_project']
  end

  def get_referenced_collection_params(params)
    if [:referenced_collection_name, :source_entity_type, :source_entity_id].all?{ |key| params.has_key?(key) }
      self.referenced_collection_name = params[:referenced_collection_name]

      self.source_entity_type = params[:source_entity_type]
      self.source_entity_id = params[:source_entity_id]
      self.use_referenced_collection_scope = true

      self.source_entity ||= self.source_entity_type.safe_constantize&.find_by(id: self.source_entity_id)
      raise StatementInvalid.new('Source entity is not found') if self.source_entity.nil?

      self.source_entity.send(self.referenced_collection_name)
    end
  end


  def set_referenced_collection_params(params)
    entity_scope = get_referenced_collection_params(params)

    set_entity_scope(entity_scope.visible) if entity_scope
  end

  def to_params(options = {})
    easy_query_params = { :set_filter => '1', :type => self.class.name, :fields => [], :operators => {}, :values => {} }

    self.filters.each do |f, o|
      easy_query_params[:fields] << f
      easy_query_params[:operators][f] = o[:operator]
      easy_query_params[:values][f]    = o[:values]
    end

    self.custom_formatting.each do |scheme, filters|
      easy_query_params[scheme]             ||= {}
      easy_query_params[scheme][:fields]    ||= []
      easy_query_params[scheme][:operators] ||= {}
      easy_query_params[scheme][:values]    ||= {}
      filters.each do |field, options|
        easy_query_params[scheme][:fields] << field
        easy_query_params[scheme][:operators][field] = options[:operator]
        easy_query_params[scheme][:values][field]    = options[:values]
      end
    end

    easy_query_params[:group_by]           = self.group_by
    easy_query_params[:outputs]            = self.outputs
    easy_query_params[:column_names]       = (self.column_names || []).collect(&:to_s)
    easy_query_params[:load_groups_opened] = self.load_groups_opened ? '1' : '0'
    easy_query_params[:show_sum_row]       = self.show_sum_row ? '1' : '0'

    if self.period_columns? || !self.chart_settings['period_column'].blank? || (self.settings['report_group_by'].is_a?(Array) && available_columns.detect { |col| self.settings['report_group_by'].include?(col.name.to_s) && col.date? })
      easy_query_params[:period_zoom]             = self.period_zoom
      easy_query_params[:period_start_date]       = self.period_start_date
      easy_query_params[:period_end_date]         = self.period_end_date
      easy_query_params[:period_date_period]      = self.period_date_period
      easy_query_params[:period_date_period_type] = self.period_date_period_type
    end

    if self.currency_columns?
      easy_query_params[:easy_currency_code] = self.easy_currency_code
    end

    easy_query_params[:calculation_formula] = self.calculation_formula if !self.calculation_formula.blank?

    if outputs.include?('chart') && !options[:export]
      easy_query_params[:chart_settings]     = self.chart_settings.dup
      easy_query_params[:chart]              = '1'
      easy_query_params[:load_groups_opened] = '0'
      easy_query_params[:show_sum_row]       = '1'
    end

    easy_query_params[:settings] ||= {}
    if outputs.include?('report')
      easy_query_params[:settings][:report_group_by]   = settings['report_group_by'] if settings['report_group_by']
      easy_query_params[:settings][:report_sum_column] = settings['report_sum_column'] if settings['report_sum_column']
    end

    easy_query_params[:sort]             = @sort_helper.to_param if @sort_helper

    easy_query_params[:dont_use_project] = '1' if self.dont_use_project
    easy_query_params[:show_avatars]     = self.show_avatars ? '1' : '0'

    if query_string.present?
      easy_query_params[:query_string] = query_string
    end

    shrink_params(easy_query_params.merge(export: options[:export]))
  end

  # return rails url params => *Hash*
  def url(options = {})
    options = options.to_unsafe_hash if options.respond_to?(:to_unsafe_hash)
    opts    = shrink_params(options.deep_symbolize_keys)
    if self.new_record?
      entity_easy_query_url(self.to_params(options.slice(:export)).merge(opts))
    else
      entity_easy_query_url({ :query_id => self }.merge(opts))
    end
  end

  # return rails path => *String*
  def path(options = {})
    options = options.to_unsafe_hash if options.respond_to?(:to_unsafe_hash)
    opts    = shrink_params(options.deep_symbolize_keys)
    if self.new_record?
      entity_easy_query_path(self.to_params(options.slice(:export)).merge(opts))
    else
      entity_easy_query_path({ :query_id => self }.merge(opts))
    end
  end

  def entity_easy_query_url_params(options)
    ActiveSupport::Deprecation.warn 'Do not use url params for EasyQuery'
    { :controller => self.easy_query_entity_controller, :action => self.easy_query_entity_action, :project_id => self.project }.merge(options)
  end

  def entity_easy_query_path(options = {})
    options = options.dup

    polymorphic_path([(options.delete(:project) || self.project), self.entity], options)
  end

  def entity_easy_query_url(options = {})
    options = options.dup

    polymorphic_url([(options.delete(:project) || self.project), self.entity], options)
  end

  def entity_context_menu_path(options = {})
    {}
  end

  def extended_period_options
    {}
  end

  def require_is_tagged?
    self.require_is_tagged == true
  end

  def quote_column_name(column_name)
    self.entity.connection.quote_column_name(column_name)
  end

  def quote_table_name(table_name)
    self.entity.connection.quote_table_name(table_name)
  end

  def get_custom_sql_for_field(field, operator, value)
    nil
  end

  def statement_skip_fields
    []
  end

  def add_statement_sql_before_filters
    nil
  end

  def display_as_tree?
    false
  end

  def display_entity_count?
    true
  end

  def default_filter_options?
    self.filters == self.default_filter
  end

  def default_filter
    JSON[(get_default_values_from_easy_settings('default_filters') || Hash.new).to_json].dup
  end

  def default_custom_formatting
    JSON[(get_default_values_from_easy_settings('default_custom_formatting') || Hash.new).to_json].dup
  end

  def default_group_by
    get_default_values_from_easy_settings('grouped_by')
  end

  def default_show_sum_row
    get_default_values_from_easy_settings('show_sum_row')
  end

  def default_load_groups_opened
    get_default_values_from_easy_settings('load_groups_opened')
  end

  def default_show_avatars
    get_default_values_from_easy_settings('show_avatars')
  end

  def default_daily_snapshot
    false
  end

  def default_period_start_date
    get_default_values_from_easy_settings('period_start_date')
  end

  def default_period_end_date
    get_default_values_from_easy_settings('period_end_date')
  end

  def default_period_date_period
    get_default_values_from_easy_settings('period_date_period')
  end

  def default_period_date_period_type
    get_default_values_from_easy_settings('period_date_period_type')
  end

  def default_period_zoom
    get_default_values_from_easy_settings('period_zoom')
  end

  def default_outputs
    get_default_values_from_easy_settings('default_outputs')
  end

  def sql_for_custom_field(field, operator, value, custom_field_id)
    filter = self.available_filters[field]

    return nil unless filter

    if (filter[:field].format.name == 'easy_lookup') || (filter[:field].format.target_class && filter[:field].format.target_class <= User)
      if value.is_a?(Array) && value.delete('me')
        value.push User.current.id.to_s
      end
    end

    if (filter[:field].format.name == 'easy_lookup') || (filter[:field].format.target_class && filter[:field].format.target_class <= Group)
      if value.is_a?(Array) && value.delete('me_and_my_groups')
        value.concat(User.current.group_ids.map(&:to_s))
      end
    end

    sql_for_custom_field_without_filter(field, operator, value, filter[:field])
  end

  def sql_for_custom_field_without_filter(field, operator, value, custom_field)

    operator             = operator.to_s
    db_table             = CustomValue.table_name
    db_field             = 'value'
    db_entity_table_name = entity_table_name.dup
    not_in               = nil

    if operator == '!'
      # Makes ! operator work for custom fields with multiple values
      operator = '='
      not_in   = 'NOT '
    elsif operator == '=' && (['date', 'datetime'].include?(custom_field.field_format))
      val = Array(value).first
      if val.present? && (time_value = begin
        ; val.to_time;
      rescue;
        nil;
      end)
        operator = 'date_period_2'
        value    = { from: time_value, to: end_of_period_zoom(time_value) }
      end
    end

    if field =~ /^(.+\.)*(.+)_cf_\d+/
      assoc       = $2
      real_tbl    = $1 ? $1[0..-2].presence : nil
      real_entity = real_tbl ? real_tbl.singularize.classify.safe_constantize : entity
      assoc_klass = real_entity.reflect_on_association(assoc.to_sym)
      assoc_klass ||= real_entity.reflect_on_association(assoc.singularize.to_sym)
      customized_class = assoc_klass.klass.base_class rescue nil

      if customized_class && assoc_klass.collection?
        db_entity_table_name = assoc
        customized_key       = 'id'
      elsif assoc_klass && assoc_klass.through_reflection
        db_entity_table_name = assoc_klass.through_reflection.klass.table_name
        customized_key       = assoc_klass.foreign_key.to_s
      elsif assoc_klass
        customized_key    = assoc_klass.foreign_key.to_s
        polymorphic_assoc = real_entity.reflections.values.detect { |ref| ref.polymorphic? && ref.foreign_key == customized_key }
        if polymorphic_assoc&.foreign_type
          customized_type = polymorphic_assoc.foreign_type
        end
      else
        customized_key = "#{assoc}_id"
      end

      raise "Unknown Entity association #{assoc} (#{self.class}##{real_entity})" unless customized_class
    else
      customized_key   = 'id'
      customized_class = entity.base_class
    end

    real_tbl ||= db_entity_table_name
    where    = sql_for_field(field, operator, value, db_table, db_field, true)

    if /[<>]/.match?(operator)
      where = "(#{where}) AND " if where.present?
      where << "#{db_table}.#{db_field} <> ''"
    elsif operator == 'date_period_1' && value.is_a?(Hash) && !value[:period].blank? && [:in_less_than_n_days, :in_more_than_n_days, :in_next_n_days, :less_than_ago_n_days, :more_than_ago_n_days, :in_past_n_days].include?(value[:period].to_sym)
      where = "(#{where}) AND " if where.present?
      where << "#{db_table}.#{db_field} <> ''"
    end

    sql = '('
    sql << "#{real_tbl}.#{customized_key} IS NULL OR " if operator.include?('!')
    sql << "#{real_tbl}.#{customized_type} = '#{customized_class}' AND " if customized_type
    sql << "#{real_tbl}.#{customized_key} #{not_in}IN (" +
        "SELECT #{customized_class.table_name}.id FROM #{customized_class.table_name}" +
        " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='#{customized_class}' AND #{db_table}.customized_id=#{customized_class.table_name}.id AND #{db_table}.custom_field_id=#{custom_field.id} WHERE"
    sql << " (#{where}) AND" if where.present?
    sql << " (#{custom_field.visibility_by_project_condition})))"

    sql
  end

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter = false)
    operator = operator.to_s
    value    = Array(value) if value.is_a?(String)
    sql      = ''
    #custom_field does not exists - no actually it means it is not a filter, and it is not the same!!
    #TODO: if the cf does not exist, it should be catched higher, but is it?
    # return sql if is_custom_filter && !field_settings

    type = type_for(field)
    if db_table.blank?
      full_db_field_name = db_field
    else
      full_db_field_name = "#{db_table}.#{db_field}"
    end

    if type == :currency && easy_currency_code
      full_db_field_name = "#{full_db_field_name}_#{easy_currency_code}"
    end

    # sometimes operator is not saved
    if operator.blank? && value.is_a?(Hash) && value.key?(:period)
      if value[:period].blank?
        operator = 'date_period_2'
      else
        operator = 'date_period_1'
      end
    end

    case operator
    when '='
      if value.any?
        case type
        when :date, :date_past, :date_period
          sql = date_clause(db_table, db_field, parse_date(value.first), parse_date(value.first), field: field)
        when :integer
          int_values = value.first.to_s.scan(/[+-]?\d+/).map(&:to_i).join(',')
          if int_values.present?
            if is_custom_filter
              sql = "(#{full_db_field_name} <> '' AND CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(30,0)) IN (#{int_values}))"
            else
              sql = "#{full_db_field_name} IN (#{int_values})"
            end
          else
            sql = '1=0'
          end
        when :float, :currency
          float_val = value.first.to_f
          if is_custom_filter
            sql = "(#{full_db_field_name} <> '' AND CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(30,3)) BETWEEN #{float_val - 1e-5} AND #{float_val + 1e-5})"
          else
            sql = "#{full_db_field_name} BETWEEN #{float_val - 1e-5} AND #{float_val + 1e-5}"
          end
        when :boolean
          if value.first == ''
            sql = "#{full_db_field_name} IS NULL"
          else
            sql = "#{full_db_field_name} IN (#{(value.first.to_i == 1) ? EasyQuery.connection.quoted_true : EasyQuery.connection.quoted_false})"
          end
        else
          sql = '('
          if !db_table.blank? && /^(\w+.)?\w+$/.match?(full_db_field_name)
            sql << Arel::Attributes::Attribute.new(Arel::Table.new(db_table), db_field).in(value).to_sql
          else
            sql << queried_class.send(:sanitize_sql_for_conditions, ["#{full_db_field_name} IN (?)", value])
          end
          if value.size == 1 && value[0].blank?
            sql << " OR #{full_db_field_name} IS NULL"
          end
          sql << ')'
        end
      else
        # IN an empty set
        sql = '1=0'
      end
    when '!'
      if value.any?
        sql = '('
        sql << queried_class.send(:sanitize_sql_for_conditions, ["#{full_db_field_name} NOT IN (?)", value])
        if value.size == 1 && value[0].blank?
          sql << " OR #{full_db_field_name} IS NOT NULL"
        else
          sql << " OR #{full_db_field_name} IS NULL"
        end
        sql << ')'
      else
        # NOT IN an empty set
        sql = '1=1'
      end
    when '!*'
      sql = "#{full_db_field_name} IS NULL"
      sql << " OR #{full_db_field_name} = ''" if (is_custom_filter || [:text, :string].include?(type))
    when '*'
      sql = "#{full_db_field_name} IS NOT NULL"
      sql << " AND #{full_db_field_name} <> ''" if (is_custom_filter || [:text, :string].include?(type))
    when '>='
      if [:date, :date_past, :date_period].include?(type)
        sql = date_clause(db_table, db_field, parse_date(value.first), nil, field: field)
      else
        if is_custom_filter
          sql = "CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(60,3)) >= #{value.first.to_f}"
        else
          sql = "#{full_db_field_name} >= #{value.first.to_f}"
        end
      end
    when '<='
      if [:date, :date_past, :date_period].include?(type)
        sql = date_clause(db_table, db_field, nil, parse_date(value.first), field: field)
      else
        if is_custom_filter
          sql = "CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(60,3)) <= #{value.first.to_f}"
        else
          sql = "#{full_db_field_name} <= #{value.first.to_f}"
        end
      end
    when '><'
      if [:date, :date_past, :date_period].include?(type)
        sql = date_clause(db_table, db_field, parse_date(value[0]), parse_date(value[1]), field: field)
      else
        if is_custom_filter
          sql = "CAST(CASE #{full_db_field_name} WHEN '' THEN '0' ELSE #{full_db_field_name} END AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        else
          sql = "#{full_db_field_name} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        end
      end
    when 'o'
      case field
      when 'status_id'
        sql = "#{IssueStatus.table_name}.is_closed=#{self.class.connection.quoted_false}"
      when 'fixed_version_id'
        sql = "#{Version.table_name}.status = 'open'"
      end
    when 'c'
      case field
      when 'status_id'
        sql = "#{IssueStatus.table_name}.is_closed=#{self.class.connection.quoted_true}"
      when 'fixed_version_id'
        sql = "#{Version.table_name}.status = 'closed'"
      end
    when '>dd'
      if field == 'fixed_version_id'
        # date_clause give <= operator so there must be -1 day
        sql = date_clause(Version.table_name, 'effective_date', nil, (User.current.today - 1.day), field: field)
      end
    when '><t-'
      # between today - n days and today
      sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, 0, field: field)
    when '>t-'
      # >= today - n days
      sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, nil, field: field)
    when '<t-'
      # <= today - n days
      sql = self.relative_date_clause(db_table, db_field, nil, -value.first.to_i, field: field)
    when 't-'
      # = n days in past
      sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, -value.first.to_i, field: field)
    when '><t+'
      # between today and today + n days
      sql = self.relative_date_clause(db_table, db_field, 0, value.first.to_i, field: field)
    when '>t+'
      # >= today + n days
      sql = self.relative_date_clause(db_table, db_field, value.first.to_i, nil, field: field)
    when '<t+'
      # <= today + n days
      sql = self.relative_date_clause(db_table, db_field, nil, value.first.to_i, field: field)
    when 't+'
      # = today + n days
      sql = self.relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i, field: field)
    when 't'
      # = today
      sql = self.relative_date_clause(db_table, db_field, 0, 0, field: field)
    when 'w'
      # = this week
      first_day_of_week = EasyExtensions::Calendars::Calendar.first_wday
      day_of_week       = User.current.today.cwday
      days_ago          = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql               = self.relative_date_clause(db_table, db_field, -days_ago, -days_ago + 6, field: field)
    when 'date_period_1'
      case value[:period].to_s.to_sym
      when :is_null
        sql = "#{full_db_field_name} IS NULL"
        sql << " OR #{full_db_field_name} = ''" if is_custom_filter
      when :is_not_null
        sql = "#{full_db_field_name} IS NOT NULL"
        sql << " AND #{full_db_field_name} <> ''" if is_custom_filter
      when :in_less_than_n_days
        operator = '<t+'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :in_more_than_n_days
        operator = '>t+'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :in_next_n_days
        operator = '><t+'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :in_n_days
        operator = 't+'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :less_than_ago_n_days
        operator = '>t-'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :more_than_ago_n_days
        operator = '<t-'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :in_past_n_days
        operator = '><t-'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      when :ago_n_days
        operator = 't-'
        sql      = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
      else
        sql = get_date_clause('date_period_1', value, db_table, db_field, field)
      end
    when 'date_period_2'
      sql = get_date_clause('date_period_2', value, db_table, db_field, field)
    when '~'
      sql = sql_contains("#{full_db_field_name}", value.first)
    when '!~'
      sql = sql_contains("#{full_db_field_name}", value.first, false)
    when '^~'
      sql = sql_starts_with("#{full_db_field_name}", value.first)
    when '$~'
      sql = sql_ends_with("#{full_db_field_name}", value.first)
    else
      # Rails.logger.error("Unknown query operator #{operator}, query #{id}")

      # To avoid errors duplication
      errors.add(:query_string) if !errors.added?(:query_string)
      return '1=0'
    end

    return sql
  end

  def get_date_clause(type, value, db_table, db_field, field)
    case type
    when 'date_period_2'
      period_dates = self.get_date_range('2', value[:period], value[:from], value[:to], 0, '', '', value[:shift])
    when 'date_period_1'
      period_dates = self.get_date_range('1', value[:period], value[:from], value[:to], 0, value[:period_days2], value[:period_days], value[:shift])
    else
      return ''
    end
    field_settings = self.available_filters[field] || {}
    if field_settings[:time_column]
      time_from = period_dates[:from].try(:to_time)
      time_to   = period_dates[:to].try(:to_time)
      period_dates[:from] = User.current.convert_time_to_user_civil_time_in_zone(time_from)&.beginning_of_day&.utc
      period_dates[:to]   = User.current.convert_time_to_user_civil_time_in_zone(time_to)&.end_of_day&.utc
    end
    self.date_clause(db_table, db_field, period_dates[:from], period_dates[:to], field: field)
  end

  # Returns a SQL LIKE statement with wildcards
  def sql_like(db_field, value, match = true, prefix = '%', suffix = '%')
    queried_class.send :sanitize_sql_for_conditions,
                       [Redmine::Database.like(db_field, '?', :match => match), "#{prefix}#{value}#{suffix}"]
  end

  def sql_starts_with(db_field, value, match = true)
    sql_like(db_field, value, match, '')
  end

  def sql_ends_with(db_field, value, match = true)
    sql_like(db_field, value, match, '%', '')
  end

  def sql_contains(db_field, value, match = true)
    sql_like(db_field, value, match)
  end

  def sql_for_main_project_field(field, operator, value)
    op    = 'NOT ' if operator == '!' || operator == '!*'
    value = Array(value)
    value << 0 if value.empty? # value can be [] -> SQL error on "id IN ()"
    sql_cond = 'root_project.id IN (' + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(',') + ') AND root_project.lft <= projects.lft AND root_project.rgt >= projects.rgt AND ' if operator == '=' || operator == '!'
    return "#{op}EXISTS(SELECT * FROM projects root_project WHERE #{sql_cond}projects.parent_id IS NOT NULL)"
  end

  def sql_for_favorited_field(field, operator, value)
    fav_tbl = EasyFavorite.table_name
    "#{value[0] == '1' ? '' : 'NOT '}EXISTS (SELECT 1 FROM #{fav_tbl} WHERE #{fav_tbl}.user_id = #{User.current.id} AND #{fav_tbl}.entity_type = '#{self.entity.name}' AND #{fav_tbl}.entity_id = #{entity_table_name}.id)"
  end

  def add_custom_field_filter(field, assoc = nil, dont_use_assoc_filter_name: false, group_name: nil)
    options = field.query_filter_options(self)
    if field.format.target_class && field.format.target_class <= User
      if options[:values].is_a?(Array) && User.current.logged?
        options[:values].unshift ["<< #{l(:label_me)} >>", 'me']
      end
    end

    filter_id       = "cf_#{field.id}"
    filter_name     = field.name
    filter_group    = group_name || EasyQuery.column_filter_group_name(assoc)
    filter_includes = []

    if assoc.present?
      filter_id       = "#{assoc}_#{filter_id}"
      filter_name     = l("label_attribute_of_#{assoc}", :name => filter_name) if !dont_use_assoc_filter_name
      association     = entity.reflect_on_association(assoc)
      filter_includes = [assoc] if association && association.collection?
    end

    add_available_filter filter_id, options.merge({
                                                      :name     => filter_name,
                                                      :field    => field,
                                                      :group    => filter_group,
                                                      :includes => filter_includes
                                                  })
  end

  def self.column_filter_group_name(assoc = nil)
    assoc.present? ? l("field_#{assoc}") + ' ' + l(:label_filter_group_custom_fields_suffix) : l(:label_filter_group_custom_fields)
  end

  def add_custom_fields_filters(scope, assoc = nil, dont_use_assoc_filter_name: false, group_name: nil)
    scope.visible.where(:is_filter => true).sorted.each do |field|
      add_custom_field_filter(field, assoc, dont_use_assoc_filter_name: dont_use_assoc_filter_name, group_name: group_name)
    end
  end

  def add_associations_custom_fields_filters(*associations)
    fields_by_class = CustomField.visible.where(:is_filter => true).group_by(&:class)
    associations.each do |assoc|
      association_klass = entity.reflect_on_association(assoc).klass
      fields_by_class.each do |field_class, fields|
        if field_class.customized_class && field_class.customized_class <= association_klass
          fields.sort.each do |field|
            add_custom_field_filter(field, assoc)
          end
        end
      end
    end
  end

  # == Options
  # only:: An Array of allowed tokens (can be String or Reqexpt)
  #
  def add_associations_filters(easy_query_class, options = {})
    q         = easy_query_class.new
    q.project = project

    association_name      = options[:association_name] || q.entity.name.underscore.to_sym
    filter_name_prefix    = options[:filter_name_prefix] || "#{q.entity.table_name}."
    cf_filter_name_prefix = options[:cf_filter_name_prefix] || "#{association_name}_"
    only                  = options[:only]

    association = self.entity.reflect_on_association(association_name)
    return unless association.nil? || association.belongs_to? || association.has_one?

    q.available_filters.each do |filter_name, filter_options|
      # Statement is assembled by some magic
      next if q.statement_skip_fields.include?(filter_name)

      # Have no idea
      next if filter_options[:assoc].present?

      # A column from other table
      # Would required too much logic
      next if filter_name.include?('.')

      # 1:N
      # Also it makes SQL very complicated
      next if filter_options[:includes].present?

      # Joins through more table is complicated
      next if filter_options[:joins].present?

      # Custom SQL
      # Usually is not counted that will be called from another query
      next if q.respond_to?(sql_for_field_method_name(filter_name))

      # User can choose what filters are wanted
      next if only && only.none? { |token| token === filter_name }
      new_filter_options = filter_options.dup

      # Associated CF from association via other associations
      # For example: EasyPriceBookRecord have invoice which have client which have CF
      if options[:skip_associated_cf] && /\A.+_cf_\d+\Z/.match?(filter_name)
        next
      end

      if options[:skip_all_cf] && filter_name.include?('cf_')
        next
      end

      if /^cf_\d+/.match?(filter_name)
        new_filter_name = "#{cf_filter_name_prefix}#{filter_name}"
      else
        new_filter_name = "#{filter_name_prefix}#{filter_name}"
      end

      unless /\A.+ \(.+\)\z/.match?(new_filter_options[:name].to_s)
        new_filter_options[:name] = "#{filter_options[:name]} (#{q.default_name})"
      end

      if (group_name = options[:group_name]).present?
        new_filter_options[:group] = group_name
      end

      new_filter_options[:assoc]    = association_name
      new_filter_options[:includes] = Array.wrap(new_filter_options[:includes]).map { |i| { association_name => i } } << association_name
      new_filter_options[:includes] << { association_name => q.default_find_include } if q.default_find_include.any?
      new_filter_options[:joins] = Array.wrap(new_filter_options[:joins]).map { |i| { association_name => i } }
      add_available_filter(new_filter_name, new_filter_options)

      self.add_columns_with_me(new_filter_name) if q.columns_with_me.include?(filter_name)
    end
  end

  # return type = :sql || :array
  def joins_for_order_statement(order_options, return_type = :sql, uniq = true)
    joins = []

    order_options.scan(/cf_\d+/).uniq.each do |name|
      column = available_columns.detect { |c| c.name.to_s.end_with?(name) }
      join   = column && column.additional_joins(self.entity, return_type, uniq)
      joins.concat(join) if join
    end if order_options

    additional_joins = Array.wrap(add_additional_order_statement_joins(order_options))
    associations     = available_columns.select(&:assoc).map(&:assoc_class).uniq
    associations.each do |assoc|
      klass            = associated_query = assoc
      associated_query = klass.associated_query_class if klass.respond_to?(:associated_query_class)
      additional_joins.concat(Array.wrap(associated_query.new.add_additional_order_statement_joins(order_options))) if associated_query
    end
    joins.concat(additional_joins) if additional_joins.any?

    case return_type
    when :sql
      joins.any? ? joins.join(' ') : nil
    when :array
      joins
    else
      raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

  def add_additional_order_statement_joins(order_options)
    ''
  end

  # Returns a SQL clause for a date or datetime field.
  #
  # @param [String] db_table name of database table
  # @param [String] db_field name of database column
  # @param [Date, Time or DateTime] from left side of interval
  # @param [Date, Time or DateTime] to right side of interval
  # @param [Boolean] absolute_time
  # @param [Boolean] is_custom_filter
  # @param [String] field name of EasyQuery filter or column
  # @return [String] SQL clause
  #
  def date_clause(db_table, db_field, from, to, absolute_time: false, is_custom_filter: (db_table == 'custom_values'), field: nil)
    s                       = []
    user                    = User.current
    full_db_field_statement = "#{db_table}.#{db_field}"

    if is_custom_filter
      full_db_field_statement = timestamp_cast(full_db_field_statement)
      is_date_cf              = self.get_column(field)&.date_time?
    end

    if from
      from_operator = ">"

      from = if from.is_a?(Time) && !from.is_a?(ActiveSupport::TimeWithZone)
               absolute_time = true
               from_operator = ">="
               from
             elsif absolute_time && from.is_a?(DateTime)
               Time.local(from.year, from.month, from.day, from.hour, from.minute, from.second)
             else
               if is_custom_filter && is_date_cf
                 t = user.user_civil_time_in_zone(from.year, from.month, from.day)
                 from.is_a?(Date) ? t : t - 1
               elsif is_custom_filter
                 Time.utc(from.year, from.month, from.day).yesterday
               else
                 Time.local(from.year, from.month, from.day).yesterday
               end
             end

      if self.class.default_timezone == :utc || is_custom_filter
        from = from.utc
      end

      if is_custom_filter && is_date_cf
        # counteracting database localization in quoted_date since the value is in UTC
        from = Time.local(from.year, from.month, from.day, from.hour).utc
      elsif !absolute_time
        from = from.end_of_day
      end

      s << ("#{full_db_field_statement} #{from_operator} '%s'" % [quoted_time(from, is_custom_filter && !is_date_cf)])
    end

    if to
      to = if to.is_a?(Time) && !to.is_a?(ActiveSupport::TimeWithZone)
             absolute_time = true
             to
           elsif absolute_time && to.is_a?(DateTime)
             Time.local(to.year, to.month, to.day, to.hour, to.minute, to.second)
           else
             if is_custom_filter && is_date_cf
               user.user_civil_time_in_zone(to.year, to.month, to.day).tomorrow
             elsif is_custom_filter
               Time.utc(to.year, to.month, to.day)
             else
               Time.local(to.year, to.month, to.day)
             end
           end

      if self.class.default_timezone == :utc || is_custom_filter
        to = to.utc
      end

      if is_custom_filter && is_date_cf
        # counteracting database localization in quoted_date since the value is in UTC
        to = Time.local(to.year, to.month, to.day, to.hour).utc
      elsif !absolute_time
        to = to.end_of_day
      end

      s << ("#{full_db_field_statement} <= '%s'" % [quoted_time(to, is_custom_filter && !is_date_cf)])
    end

    s.join(' AND ')
  end

  # Returns a SQL clause for a date or datetime field not in range.
  #
  # @param [String] db_table name of database table
  # @param [String] db_field name of database column
  # @param [Date, Time or DateTime] from left side of interval
  # @param [Date, Time or DateTime] to right side of interval
  # @param [Boolean] absolute_time
  # @param [Boolean] is_custom_filter
  # @param [String] field name of EasyQuery filter or column
  # @return [String] SQL clause
  #
  def reversed_date_clause(db_table, db_field, from, to, absolute_time: false, is_custom_filter: (db_table == 'custom_values'), field: nil)
    s                       = []
    user                    = User.current
    full_db_field_statement = "#{db_table}.#{db_field}"

    if is_custom_filter
      full_db_field_statement = timestamp_cast(full_db_field_statement)
      is_date_cf              = self.get_column(field)&.date_time?
    end

    if from
      from_yesterday      = from - 1
      from_yesterday_time = if from_yesterday.is_a?(Time) && !from_yesterday.is_a?(ActiveSupport::TimeWithZone)
                              absolute_time = true
                              from_yesterday
                            elsif absolute_time && from_yesterday.is_a?(DateTime)
                              Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day, from_yesterday.hour, from_yesterday.minute, from_yesterday.second)
                            else
                              if is_custom_filter && is_date_cf
                                user.user_civil_time_in_zone(from_yesterday.year, from_yesterday.month, from_yesterday.day)
                              elsif is_custom_filter
                                Time.utc(from_yesterday.year, from_yesterday.month, from_yesterday.day)
                              else
                                Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
                              end
                            end

      if self.class.default_timezone == :utc || is_custom_filter
        from_yesterday_time = from_yesterday_time.utc
      end

      if is_custom_filter && is_date_cf
        # counteracting database localization in quoted_date since the value is in UTC
        from_yesterday_time = Time.local(from_yesterday_time.year, from_yesterday_time.month, from_yesterday_time.day, from_yesterday_time.hour).utc
      elsif !absolute_time
        from_yesterday_time = from_yesterday_time.end_of_day
      end

      s << ("#{full_db_field_statement} <= '%s'" % [quoted_time(from_yesterday_time, is_custom_filter && !is_date_cf)])
    end

    if to
      to_operator = ">"

      to_time = if to.is_a?(Time) && !to.is_a?(ActiveSupport::TimeWithZone)
                  absolute_time = true
                  to_operator   = ">="
                  to
                elsif absolute_time && to.is_a?(DateTime)
                  Time.local(to.year, to.month, to.day, to.hour, to.minute, to.second)
                else
                  if is_custom_filter && is_date_cf
                    user.user_civil_time_in_zone(to.year, to.month, to.day).tomorrow
                  elsif is_custom_filter
                    Time.utc(to.year, to.month, to.day)
                  else
                    Time.local(to.year, to.month, to.day)
                  end
                end

      if self.class.default_timezone == :utc || is_custom_filter
        to_time = to_time.utc
      end

      if is_custom_filter && is_date_cf
        # counteracting database localization in quoted_date since the value is in UTC
        to_time = Time.local(to_time.year, to_time.month, to_time.day, to_time.hour).utc
      elsif !absolute_time
        to_time = to_time.end_of_day
      end

      s << ("#{full_db_field_statement} #{to_operator} '%s'" % [quoted_time(to_time, is_custom_filter && !is_date_cf)])
    end

    if s.empty?
      ''
    else
      '(' + s.join(' OR ') + ')'
    end
  end

  # Returns a SQL clause for a date or datetime field using relative dates.
  def relative_date_clause(db_table, db_field, days_from, days_to, field: nil)
    date_clause(db_table, db_field, (days_from ? User.current.today + days_from : nil), (days_to ? User.current.today + days_to : nil), field: field)
  end

  def parse_date(arg)
    if /\A\d{4}-\d{2}-\d{2}T/.match?(arg.to_s)
      Time.parse(arg) rescue nil
    else
      Date.parse(arg) rescue nil
    end
  end

  def statement_for_searching
    columns = self.searchable_columns

    token_clauses = columns.collect { |column| "(#{Redmine::Database.like(column, '?')})" }

    if !self.entity.reflect_on_association(:custom_values).nil?
      searchable_custom_field_ids = CustomField.where(:type => "#{self.entity}CustomField", :searchable => true).pluck(:id)
      if searchable_custom_field_ids.any?
        customized_type  = "#{self.entity}CustomField".constantize.customized_class.name
        custom_field_sql = "#{self.entity.table_name}.id IN (SELECT customized_id FROM #{CustomValue.table_name}" +
            " WHERE customized_type='#{customized_type}' AND customized_id=#{self.entity.table_name}.id AND #{Redmine::Database.like('value', '?')}" +
            " AND #{CustomValue.table_name}.custom_field_id IN (#{searchable_custom_field_ids.join(',')}))"
        token_clauses << custom_field_sql
      end
    end

    token_clauses
  end

  def apply_period_filter(field)
    period_range = self.get_date_range(self.period_date_period_type, self.period_date_period, self.period_start_date, self.period_end_date)
    self.add_filter(field, 'date_period_' + self.period_date_period_type, period_range.merge(period: self.period_date_period))
  end

  def get_class_name
    self.class.name
  end

  def self.format_html_entity_name
    'easy_query'
  end

  def sql_for_group_by_month(field)
    case ActiveRecord::Base.connection.adapter_name.downcase
    when /(mysql|mariadb)/
      "DATE_FORMAT(#{self.entity.table_name}.#{field},'%Y%m')"
    when /postgresql/
      "to_char(#{self.entity.table_name}.#{field}, '%Y%m')"
    end
  end

  def sql_time_diff(time1, time2) # time2 > time1
    case ActiveRecord::Base.connection.adapter_name.downcase
    when /(mysql|mariadb)/
      "TIMESTAMPDIFF(SECOND, #{time1}, #{time2})/3600"
    when /postgresql/
      "EXTRACT(epoch FROM (#{time2} - #{time1}) )/3600"
    when /sqlserver/
      "DATEDIFF(HOUR, #{time1}, #{time2})"
    when /sqlite3/
      "(strftime('%s', \'#{time2}\') - strftime('%s', \'#{time1}\'))/3600"
    end
  end

  def summarize_column(column, entities, group = nil, options = {})
    @cached_column_sums ||= {}
    if !entities || column.sumable_sql || group
      #group due to paging - if group is on multiple pages, it count only last page
      @cached_column_sums[column] ||= self.entity_sum_by_group(column, options)
      group                       = group.first if group.is_a?(Array) && group.size == 1
      result                      = @cached_column_sums[column][nil] if group.blank?
      result                      ||= @cached_column_sums[column][group] || @cached_column_sums[column][group.to_s]
      result                      ||= @cached_column_sums[column][group.id] if group.is_a?(ActiveRecord::Base)
      result                      ||= @cached_column_sums[column][group.to_i] if group.respond_to?(:to_i) && group.to_i > 0
      result
    else
      if column.sumable_options.distinct_columns?
        unique_entities(entities, column.sumable_options.distinct_columns(:call)).sum { |i| column.value(i) || 0.0 }
      else
        entities.sum { |i| column.value(i) || 0.0 }
      end
    end
  end

  def copy(attributes = nil)
    copy            = self.dup
    copy.attributes = attributes if attributes
    copy.roles      = self.roles
    return false unless copy.save
    self.query_copies << copy
    copy
  rescue ActiveModel::ForbiddenAttributesError
    false
  end

  def class_name_underscored
    self.class.name.underscore.tr('/', '.')
  end

  def is_used_as_default_query?
    !easy_default_query_mappings.empty?
  end

  alias_method :is_used_as_default_query, :is_used_as_default_query?

  def default_query_by_role(render_context = nil)
    return nil if render_context
    return @default_query_by_role if !@default_query_by_role.nil?

    roles_ids = [nil].concat(User.current.role_ids)
    mapping   = EasyDefaultQueryMapping.where.not(easy_query_id: nil).where(entity_type: type, role_id: roles_ids).order(Arel.sql('CASE WHEN role_id IS NULL THEN 1 ELSE 0 END, position')).select(:easy_query_id).first

    if mapping
      @default_query_by_role = mapping.easy_query
    else
      @default_query_by_role = false
    end
  end

  def sql_for_tags_field(field, operator, value)
    db_table           = ActsAsTaggableOn::Tag.table_name
    tagging_table_name = ActsAsTaggableOn::Tagging.table_name
    db_field           = 'name'
    is_not             = operator.start_with?('!')
    is_all             = operator.include?('*')
    sql                = "#{ is_not ? 'NOT ' : '' } EXISTS (SELECT 1 FROM #{tagging_table_name} " \
                         "LEFT JOIN #{db_table} ON #{db_table}.id = #{tagging_table_name}.tag_id WHERE " \
                         "#{tagging_table_name}.taggable_type = '#{self.entity.base_class.name}' AND " \
                         "#{self.entity_table_name}.id = #{tagging_table_name}.taggable_id AND " \
                         "#{sql_for_field(field, is_all ? '*' : '=', value, db_table, db_field)})"
  end

  def set_as_default(role = nil)
    return if role
    EasySetting.transaction do
      options_types = %w(show_sum_row load_groups_opened show_avatars period_start_date period_end_date period_date_period period_date_period_type period_zoom)
      options_types.each do |option|
        setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_#{option}" + (render_context ? "_#{render_context}" : ''))
        setting.value = send(option)
        setting.save
      end
      filters_setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_default_filters" + (render_context ? "_#{render_context}" : ''))
      filters_setting.value = filters
      filters_setting.save
      grouped_by_setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_grouped_by" + (render_context ? "_#{render_context}" : ''))
      grouped_by_setting.value = group_by
      grouped_by_setting.save
      columns_setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_list_default_columns" + (render_context ? "_#{render_context}" : ''))
      columns_setting.value = column_names.map(&:to_s)
      columns_setting.save
      sort_setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_default_sorting_array" + (render_context ? "_#{render_context}" : ''))
      sort_setting.value = sort_criteria
      sort_setting.save
      outputs_setting       = EasySetting.find_or_create_by!(name: "#{get_class_name.underscore}_default_outputs" + (render_context ? "_#{render_context}" : ''))
      outputs_setting.value = outputs
      outputs_setting.save
    end
  end

  # Creates more compact params to address long URL issues
  # @param [Hash] params
  def shrink_params(params)
    params
  end

  # Parses compact params into standard format
  # @param [Hash] params
  def expand_params(params)
    params
  end

  def is_snapshot?
    false
  end

  protected

  def scope_for_calculations(scope)
    if scope.respond_to?(:construct_relation_for_association_calculations, true)
      scope.send(:construct_relation_for_association_calculations)
    else
      scope.send(:apply_join_dependency)
    end
  end

  private

  def group_date_period_range(filter, date)
    previous_from = filters.dig(filter, 'values', 'from').to_date rescue nil
    previous_to = filters.dig(filter, 'values', 'to').to_date rescue nil

    if previous_from && previous_to
      { from: [date, previous_from].max, to: [end_of_period_zoom(date), previous_to].min }
    else
      { from: date, to: end_of_period_zoom(date) }
    end
  end

  def get_enum_value(field, value)
    plural = field.to_s.pluralize
    return value unless entity.respond_to?(plural)
    values = entity.send(plural)
    if values.is_a?(Hash)
      if value.is_a?(Array)
        value.map { |v| values.has_key?(v) ? values[v] : v }
      else
        values.has_key?(value) ? values[value] : value
      end
    else
      value
    end
  end

  def quoted_time(time, is_custom_filter)
    if is_custom_filter
      time.strftime("%Y-%m-%d %H:%M:%S")
    else
      self.class.connection.quoted_date(time)
    end
  end

  def db_table_field(column)
    if (table_field = column.split('.')).length >= 2
      table_field.last(2)
    else
      [entity_table_name, column]
    end
  end

  def entity_column_for(field)
    field_name = field.respond_to?(:name) ? field.name.to_s : field.to_s.split('.').last
    entity.columns.detect { |c| c.name.to_s == field_name }
  end

  def get_period_filter
    column = get_column(self.chart_settings['period_column'])
    if column.try(:filter)
      self.filters[column.filter.to_s]
    else
      filter = self.filters.keys.detect { |k| k.to_s == self.chart_settings['period_column'] }
      self.filters[filter]
    end
  end

  def limit_group_ids(scope, options)
    if self.grouped? && options[:group_ids] && options[:group]
      self.group_by_statements.each_with_index do |group_statement, i|
        group_ids = options[:group_ids].map { |group_id| group_id[i] }
        with_null = " OR #{group_statement} IS NULL" if group_ids.include?(nil)
        group_ids.compact!
        group_ids.uniq!
        cast_values!(scope, group_statement, group_ids)
        scope = scope.where("(#{Arel.sql(group_statement).in(group_ids).to_sql}#{with_null})")
      end
    end
    scope
  end

  def cast_values!(scope, statement, values)
    cast_type = scope.send(:type_for, statement)
    values.map! { |v| cast_type.serialize(v) } if cast_type
  end

  def with_sort_criteria(sort_criteria, &block)
    backup             = self.sort_criteria
    self.sort_criteria = sort_criteria
    yield
  ensure
    self.sort_criteria = backup
  end

  def unique_entities(entities, distinct_columns)
    keys   = []
    result = []
    entities.each do |e|
      key = []
      distinct_columns.each do |dc|
        value = if dc.respond_to?(:call)
                  dc.call(e)
                elsif e.respond_to?(dc)
                  e.send(dc)
                end
        key << value
      end
      next if keys.include?(key)
      result << e
      keys << key
    end

    result
  end

  def custom_date_period_filter?(expression)
    expression.blank? || (expression.include?('|') && /^\d{4}/.match?(expression)) || !(/\d{4}/.match?(expression))
  end

  # return hash of sums columns for
  # * *top* - if query grouped
  # * *bottom* - extra row in list with sums of columns
  def summarize_entities(entities, group = nil, options = {})
    top, bottom      = ActiveSupport::OrderedHash.new, ActiveSupport::OrderedHash.new
    summable_columns = self.columns.select { |c| c.sumable_top? || c.sumable_bottom? }
    summable_columns.concat(self.generated_period_columns.select { |c| c.sumable? && c.visible? }) if self.period_columns?
    summable_columns.each do |column|
      if column.sumable_top? && self.grouped?
        top[column] = summarize_column(column, entities, group, options)
      end
      if column.sumable_bottom? || (column.sumable? && column.visible?)
        bottom[column] = top[column] || summarize_column(column, entities, group, options)
      end
    end
    return { :top => top, :bottom => bottom }
  end

  def clear_column_sums_cache
    @cached_column_sums = nil
  end

  def get_default_values_from_easy_settings(type, render_context = self.render_context)

    if (query = default_query_by_role(render_context))
      return case type
             when 'default_filters'
               query.filters
             when 'grouped_by'
               query.group_by
             when 'show_sum_row'
               query.show_sum_row
             when 'load_groups_opened'
               query.load_groups_opened
             when 'show_avatars'
               query.show_avatars
             when 'period_start_date'
               query.period_start_date
             when 'period_end_date'
               query.period_end_date
             when 'period_date_period'
               query.period_date_period
             when 'period_date_period_type'
               query.period_date_period_type
             when 'period_zoom'
               query.period_zoom
             when 'list_default_columns'
               query.column_names.map(&:to_s)
             when 'default_sorting_array'
               query.sort_criteria
             when 'default_custom_formatting'
               query.custom_formatting
             end
    else
      EasySetting.value("#{get_class_name.underscore}_#{type}")
    end
  end

  def sql_for_field_method_name(field)
    "sql_for_#{field.tr('.', '_')}_field"
  end

  def merge_scope(scope, options = {})
    options ||= {}
    scope   = scope.where(options[:where]) if options[:where]
    scope   = scope.where(options[:conditions]) if options[:conditions]
    scope   = scope.includes(options[:includes]) if options[:includes]
    scope   = scope.preload(options[:preload]) if options[:preload]
    scope   = scope.joins(options[:joins]) if options[:joins]
    scope   = scope.order(options[:order]) if options[:order]
    scope   = scope.group(options[:group]) if options[:group]
    scope   = scope.limit(options[:limit]) if options[:limit]
    scope   = scope.offset(options[:offset]) if options[:offset]
    scope
  end

  def merge_options(options1, options2)
    options1.merge!(options2) do |key, oldval, newval|
      if newval.is_a?(Array) && oldval.is_a?(Array)
        oldval + newval
      elsif oldval.is_a?(String) && newval.is_a?(String)
        case key
        when :where
          oldval + ' AND ' + newval
        else
          newval
        end
      else
        newval
      end
    end
  end

  def attribute_in_use?(attribute)
    column_names.include?(attribute.to_sym) || filters.key?("#{attribute}_id") || (group_by && group_by.include?(attribute)) || sort_criteria.flatten.include?(attribute)
  end

end
