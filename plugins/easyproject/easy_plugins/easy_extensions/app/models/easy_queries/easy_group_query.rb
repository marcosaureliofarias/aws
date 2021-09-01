class EasyGroupQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'lastname',    { type: :text }
      add_available_filter 'description', { type: :text }
      add_available_filter 'created_on',  { type: :date_period }
      add_available_filter 'updated_on',  { type: :date_period }
      add_principal_autocomplete_filter 'group_id', label: :label_group_plural,
                                                    source: 'visible_user_groups',
                                                    source_root: ''
    end

    add_custom_fields_filters(GroupCustomField)
  end

  def initialize_available_columns
    on_column_group(default_group_label) do

      add_available_column :lastname, sortable: "#{Group.table_name}.lastname",
                                      groupable: true,
                                      caption: :field_name
      add_available_column :description
      add_available_column EasyQueryDateColumn.new(:created_on,
                                                   sortable: "#{Group.table_name}.created_on",
                                                   groupable: true)
      add_available_column EasyQueryDateColumn.new(:updated_on,
                                                   sortable: "#{Group.table_name}.updated_on",
                                                   groupable: true)
    end

    GroupCustomField.all.each do |cf|
      add_available_column EasyQueryCustomFieldColumn.new(cf)
    end
  end

  def default_list_columns
    @default_list_columns ||= ['lastname', 'description', 'created_on']
  end

  def searchable_columns
    ["#{Principal.table_name}.login", "#{Principal.table_name}.lastname", "#{Principal.table_name}.description", "#{Principal.table_name}.firstname", "(SELECT address FROM #{EmailAddress.table_name} WHERE user_id=#{Principal.table_name}.id AND is_default = #{self.class.connection.quoted_true} LIMIT 1)"]
  end

  def entity
    Group
  end

  def sql_for_group_id_field(field, operator, value)
    if value.size == 1
      # Accepts a comma separated list of ids
      value = value.first.to_s.scan(/\d+/)
    end

    sql_for_field(field, operator, value, entity_table_name, 'id')
  end

end
