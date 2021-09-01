class EasyEntityAttribute
  include Redmine::I18n

  attr_accessor :name, :short_name, :no_link, :includes, :joins, :preload, :numeric, :assoc, :title,
                :group, :most_used, :assoc_query, :icon, :assoc_type, :permitted, :type, :attribute, :source_options

  def initialize(name, options = {})
    @name             = name.to_sym
    @short_name       = options[:short_name].to_sym if options[:short_name]
    @assoc            = options[:assoc]
    @caption_key      = options[:caption] || "field_#{name}"
    @title            = options[:title]
    @no_link          = options[:no_link].nil? ? false : options[:no_link]
    @inline           = options.key?(:inline) ? options[:inline] : true
    @icon             = options.key?(:icon) ? options[:icon] : false
    @full_rows_column = options[:full_rows_column].nil? ? false : options[:full_rows_column]
    @includes         = options[:includes]
    @joins            = Array(options[:joins])
    @preload          = options[:preload]
    @numeric          = options[:numeric]
    @group            = options[:group]
    @most_used        = options[:most_used]
    @permitted        = options[:permitted].nil? || options[:permitted]
    @css_classes      = options[:css_classes]
    @attribute        = options[:attribute] || name.to_s
    @source_options   = options[:source_options] || {}
    @type             = options[:type] || 'string'
  end

  def assoc_class
    assoc_query && assoc_query.entity
  end

  def caption(with_suffixes = false)
    @title || l(@caption_key)
  end

  def group
    @group || l(:label_column_group_other)
  end

  def other_group?
    @group.nil?
  end

  def inline?
    @inline
  end

  def visible?
    true
  end

  def permitted?
    @permitted
  end

  def numeric?
    !!@numeric
  end

  def full_rows_column?
    self.inline? && @full_rows_column
  end

  def entity_attribute_name
    @short_name.presence || @name
  end

  def assoc_column?
    @assoc.present?
  end

  def value(entity, options = {})
    return nil if entity.nil?

    if @short_name && @assoc
      method_name = "#{@assoc}.#{@short_name}"
    else
      method_name = @name
    end
    if @assoc && (reflection = get_reflection(entity, @assoc)) && reflection.collection?
      nil
    else
      entity.nested_send(method_name)
    end
  end

  def value_object(entity, options = {})
    value(entity, options)
  end

  def css_classes
    @css_classes ||= [self.name.to_s.underscore, (self.numeric? ? ((User.current.pref.number_alignment == '0') ? 'text-right' : 'text-left') : '')].reject(&:blank?).join(' ')
  end

  def sort_order_sql(query, order = nil)
    order ||= default_order
    Array(sortable).collect { |s| Arel.sql("#{s} #{order}") }
  end

  def group_by_sort_order(query, order = nil)
    if sortable
      order              ||= default_order
      sorts              = Array(sortable)
      group_statement    = group_by_statement(query)
      sortable_statement = sorts.join(', ').strip
      if group_statement == sortable_statement
        sort_order_sql(query, order)
      else
        sorts.map { |s| Arel.sql("MIN(#{s}) #{order}") }
      end
    end
  end

  def additional_group_by_for_sort(query, options = {})
    nil
  end

  private

  def get_reflection(entity, assoc)
    if entity.is_a?(SimpleDelegator)
      entity = entity.__getobj__
    end
    entity.class.reflect_on_association(assoc)
  end

end

module EasyEntityAttributeColumnExtensions

  def self.included(base)
    base.include(EasySumableAttributeColumnExtension)
  end

  # sumable => :top || :bottom || :both
  attr_accessor :sortable, :groupable, :default_order

  def initialize(name, options = {})
    super(name, options)
    self.sortable = options[:sortable].is_a?(Proc) ? options[:sortable].call : options[:sortable]
    # Redmine use always name of column. When +true+ is passed use column name as temporary fix
    if self.sortable == true
      ActiveSupport::Deprecation.warn "pass `true` as +sortable+ is deprecated. Use `sortable: \"\#{entity.table_name}.#{name}\"` instead."
      self.sortable = name.to_s
    end
    self.groupable = options[:groupable]
    if self.groupable == true
      if self.sortable.is_a?(String)
        self.groupable = self.sortable
      else
        self.groupable = name.to_s
      end
    end
    self.default_order = options[:default_order]
  end


  def sortable?
    !!sortable
  end

end

module EasySumableAttributeColumnExtension

  class EasySumableOptions

    attr_reader :custom_sql

    def initialize(*args)
      raise ArgumentError, 'Summable Options has to be build from hash' unless args.first.is_a?(Hash)
      @distinct_columns_count = 0
      parse_options(args.shift)
    end

    def parse_options(options = {})
      @custom_sql             = options[:custom_sql] || {}
      @model                  = options[:model]
      @column_name            = options[:column]
      @distinct_columns       = { :sql => [], :call => [] }
      @distinct_columns_count = 0

      distinct_columns = options.delete(:distinct_columns)
      return unless distinct_columns

      distinct_columns = Array.wrap(distinct_columns)

      has_count = @distinct_columns.keys.count
      distinct_columns.each do |dc|
        if dc.is_a?(Array)
          raise ArgumentError, 'Distinct column array has to have ' + has_count.to_s + ' members and has ' + dc.count.to_s unless dc.count == has_count
          @distinct_columns[:sql] << dc.first
          @distinct_columns[:call] << dc.second
        elsif dc.is_a?(String)
          @distinct_columns[:sql] << dc
          @distinct_columns[:call] << dc.split(',').last.to_sym
        elsif dc.is_a?(Symbol)
          @distinct_columns[:sql] << dc.to_s
          @distinct_columns[:call] << dc
        end
        @distinct_columns_count += 1
      end
    end

    # type for columns ( :sql = string to sql query, :call = callable for the entity of query)
    def distinct_columns(type = :sql)
      @distinct_columns[type]
    end

    def distinct_columns?
      @distinct_columns_count > 0
    end

    def model
      @model.constantize rescue nil
    end

    def entity_column(query, name = nil)
      if model && (col_name = (@column_name || name))
        model.columns.detect { |c| c.name.to_s == col_name }
      else
        query.send(:entity_column_for, name)
      end
    end

  end #end class SumableOptions

  attr_accessor :sumable, :sumable_sql, :polymorphic

  attr_reader :sumable_options

  def initialize(name, options = {})
    @sumable_header      = !options[:disable_header_sum]
    self.sumable         = options[:sumable]
    self.sumable_sql     = options[:sumable_sql]
    self.sumable_options = options[:sumable_options] || {}
    self.polymorphic     = options[:polymorphic]
    super(name, options)
    self.numeric = self.sumable? if self.numeric.nil?
  end

  def caption(with_suffixes = false)
    super + (with_suffixes && sumable_header? ? " (#{I18n.t(:label_aggregated_short)})" : '')
  end

  def sumable_options=(options)
    @sumable_options = EasySumableOptions.new(options, name)
  end

  def sumable?
    !sumable.nil?
  end

  def sumable_header?
    self.sumable? && @sumable_header
  end

  def sumable_top?
    return self.sumable? && (self.sumable == :top || self.sumable == :both)
  end

  def sumable_bottom?
    return self.sumable? && (self.sumable == :bottom || self.sumable == :both)
  end

  def sumable_both?
    return self.sumable? && self.sumable == :both
  end

  def polymorphic?
    !self.polymorphic.nil?
  end

  def additional_joins(entity_class, type = :sql, uniq = true)
    self.joins
  end

end
