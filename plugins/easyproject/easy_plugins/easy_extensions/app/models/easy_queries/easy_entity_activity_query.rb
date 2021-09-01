class EasyEntityActivityQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryDateColumn.new(:start_time, :title => EasyEntityActivity.human_attribute_name(:start_time), :sortable => "#{EasyEntityActivity.table_name}.start_time", :groupable => "#{EasyEntityActivity.table_name}.start_time")
      add_available_column EasyQueryColumn.new(:easy_entity_activity_attendees, :title => EasyEntityActivity.human_attribute_name(:attendees), :includes => [:easy_entity_activity_users], groupable: "COALESCE(CONCAT(#{EasyEntityActivityAttendee.table_name}.entity_type, '_', #{EasyEntityActivityAttendee.table_name}.entity_id), '_')")
      add_available_column EasyQueryColumn.new(:author, :title => EasyEntityActivity.human_attribute_name(:author_id), :sortable => lambda { User.fields_for_order_statement('authors') }, :groupable => "#{EasyEntityActivity.table_name}.author_id", :preload => [:author])
      add_available_column EasyQueryColumn.new(:category, :title => EasyEntityActivity.human_attribute_name(:category), :preload => [:category], :groupable => "#{EasyEntityActivity.table_name}.category_id")
      add_available_column EasyQueryColumn.new(:description, :title => EasyEntityActivity.human_attribute_name(:description), :inline => false)
      add_available_column EasyQueryColumn.new(:is_finished, :title => EasyEntityActivity.human_attribute_name(:is_finished))
      add_available_column EasyQueryColumn.new(:entity, :title => EasyEntityActivity.human_attribute_name(:entity), :groupable => "#{EasyEntityActivity.table_name}.entity_id", :preload => [:entity])
    end
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_principal_autocomplete_filter 'author_id', { order: 4, name: EasyEntityActivity.human_attribute_name(:author_id) }
      add_available_filter 'easy_entity_activity_attendees', { type: :list_autocomplete, source: 'easy_entity_activity_attendees', most_used: true, order: 5, name: EasyEntityActivity.human_attribute_name(:attendees) }
      add_available_filter 'created_at', { type: :date_period, time_column: true, order: 15 }
      add_available_filter 'updated_at', { type: :date_period, time_column: true, label: :label_updated_within }
      add_available_filter 'is_finished', { type: :boolean, order: 11, name: EasyEntityActivity.human_attribute_name(:is_finished), attr_reader: true, attr_writer: true }
      add_available_filter 'description', { type: :text, order: 14, name: EasyEntityActivity.human_attribute_name(:description) }
      add_available_filter 'category_id', { type: :list, order: 2, values: Proc.new { EasyEntityActivityCategory.sorted.collect { |s| [s.name, s.id.to_s] } },
                                            name: EasyEntityActivity.human_attribute_name(:category_id)
      }
      add_available_filter 'start_time', { type: :date_period, time_column: true, order: 20, name: EasyEntityActivity.human_attribute_name(:start_time) }
      add_available_filter 'entity_type', { type: :list, order: 3,
                                            values: -> { EasyEntityActivity.distinct.pluck(:entity_type).collect { |type| [l("label_#{type.underscore}"), type] } },
                                            name: l(:field_entity_type) }
    end
  end

  def entity
    EasyEntityActivity
  end

  def default_list_columns
    super.presence || %w[entity category start_time easy_entity_activity_attendees author description]
  end

  def calendar_support?
    true
  end

  def sql_for_easy_entity_activity_attendees_field(field, operator, value)
    db_table  = EasyEntityActivityAttendee.table_name
    val       = Array.wrap(value)
    condition = ''
    is_not    = operator.to_s.start_with?('!')
    if !val.first.blank?
      if val.delete('me')
        val << "Principal_#{User.current.id}"
      end
      val = val.select { |x| x.include?('_') }
      if val == ['_']
        is_not = true
        condition << " AND #{db_table}.entity_id IS NOT NULL"
      elsif val.any?
        condition << ' AND ('
        condition << val.map { |v| v.split('_') }.map { |f| "(#{db_table}.entity_type = '#{f[0]}' AND #{db_table}.entity_id = #{f[1]})" }.join(' OR ')
        condition << ')'
      end
    end
    "#{is_not ? 'NOT ' : ''}EXISTS (SELECT 1 FROM #{db_table} where #{db_table}.easy_entity_activity_id = #{EasyEntityActivity.table_name}.id#{condition})"
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{entity_table_name}.author_id"
      end
    end
    joins
  end

  def objects_for(field, klass = nil, filters = self.filters)
    if field == 'easy_entity_activity_attendees'
      field_ids = values_for(field)
      objects   = []
      begin
        field_ids.map { |x| x.split('_') }.group_by { |split| split[0] }.each do |klass, values|
          if (klass == 'me') && User.current.logged?
            objects << ENTITY_OBJECT.new('me', "<< #{l(:label_me)} >>")
          else
            objects_raw = klass.constantize.where(id: values.map{|value| value[1].to_i})
            objects_raw.each do |object|
              objects << ENTITY_OBJECT.new("#{object.class.base_class}_#{object.id}", object.to_s)
            end
          end
        end
      rescue
        nil
      end
      objects
    else
      super
    end
  end
end
