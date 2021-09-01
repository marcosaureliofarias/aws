class EasyBroadcastQuery < EasyQuery

  self.queried_class = EasyBroadcast

  def initialize_available_filters
    add_available_filter 'message', name: ::EasyBroadcast.human_attribute_name(:message), type: :text
    add_available_filter 'start_at', name: ::EasyBroadcast.human_attribute_name(:start_at), type: :date_period, time_column: true
    add_available_filter 'end_at', name: ::EasyBroadcast.human_attribute_name(:end_at), type: :date_period, time_column: true
    add_principal_autocomplete_filter 'author_id', name: ::EasyBroadcast.human_attribute_name(:author_id)
    add_available_filter 'easy_user_type_id', name: ::EasyBroadcast.human_attribute_name(:easy_user_types), type: :list, values: Proc.new { EasyUserType.sorted.map { |type| [type.name, type.id] } }
    add_available_filter 'created_at', name: ::EasyBroadcast.human_attribute_name(:created_at), type: :date_period, time_column: true
    add_available_filter 'updated_at', name: ::EasyBroadcast.human_attribute_name(:updated_at), type: :date_period, time_column: true

  end

  def available_columns
    return @available_columns if @available_columns

    add_available_column 'author', title: ::EasyBroadcast.human_attribute_name(:author), sortable: lambda { User.fields_for_order_statement('author') }, groupable: true, preload: [:author]
    add_available_column 'message', inline: false, caption: ::EasyBroadcast.human_attribute_name(:message), title: ::EasyBroadcast.human_attribute_name(:message)
    add_available_column 'start_at', sortable: "#{EasyBroadcast.table_name}.start_at", title: ::EasyBroadcast.human_attribute_name(:start_at)
    add_available_column 'end_at', sortable: "#{EasyBroadcast.table_name}.end_at", title: ::EasyBroadcast.human_attribute_name(:end_at)
    add_available_column 'created_at', sortable: "#{EasyBroadcast.table_name}.created_at", caption: ::EasyBroadcast.human_attribute_name(:created_at), title: ::EasyBroadcast.human_attribute_name(:created_at)
    add_available_column 'updated_at', sortable: "#{EasyBroadcast.table_name}.updated_at", caption: ::EasyBroadcast.human_attribute_name(:updated_at), title: ::EasyBroadcast.human_attribute_name(:updated_at)
    add_available_column 'easy_user_types', caption: ::EasyBroadcast.human_attribute_name(:easy_user_types), title: ::EasyBroadcast.human_attribute_name(:easy_user_types), preload: [:easy_user_types]

    @available_columns
  end

  def default_list_columns
    super.presence || %w[message start_at end_at easy_user_types author]
  end

  def add_additional_order_statement_joins(order_options)
    sql = []
    if order_options.present?
      if order_options.include?('author')
        sql << "LEFT OUTER JOIN #{User.quoted_table_name} author ON author.id = #{self.entity.quoted_table_name}.author_id"
      end
    end
    sql
  end

  def sql_for_easy_user_type_id_field(field, operator, value)
    #broadcast_ids = ActiveRecord::Base.connection.select_values("SELECT distinct easy_broadcast_id from easy_broadcasts_user_types where easy_user_type_id in (#{value.join(',')})")
    broadcast_ids = EasyBroadcast.joins(:easy_user_types).where(easy_broadcasts_user_types: { easy_user_type_id: value }).distinct.pluck(:id)

    if broadcast_ids.any?
      "#{EasyBroadcast.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (#{broadcast_ids.join(',')})"
    else
      '1=0'
    end
  end

end
