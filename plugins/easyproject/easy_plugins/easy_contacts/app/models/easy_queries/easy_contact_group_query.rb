class EasyContactGroupQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_contacts
  end

  def available_filters
    return @available_filters unless @available_filters.blank?
    group = l("label_filter_group_easy_contact_group_query")
    @available_filters = {
      'group_name' => { :type => :text, :order => 1, :group => group },
      'entity_type' => { :type => :list, :order => 2,:values => [
          [l('filter.project_groups'), 'Project'],[l('filter.personal_groups'),'User']
        ], :name => l(:field_easy_contact_group_entity_type), :group => group }
    }
    @available_filters['entity_id'] = { :type => :list, :order => 3, :values => User.active.collect{|u| [u.to_s,u.id.to_s]}, :name => l(:field_easy_contact_group_entity), :group => group } if User.current.admin?
    add_custom_fields_filters(EasyContactGroupCustomField)

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      group = l("label_filter_group_easy_contact_group_query")
      @available_columns = [
        EasyQueryColumn.new(:group_name, :sortable => "#{EasyContactGroup.table_name}.group_name", :group => group),
        EasyQueryColumn.new(:group_type, :groupable => EasyContactGroup.group_type_sql, :group => group)
      ]
      @available_columns += EasyContactGroupCustomField.all.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }
      @available_columns_added = true
    end
    @available_columns
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['lft', 'asc']]
  end

  def entity
    EasyContactGroup
  end

  def self.chart_support?
    true
  end
end

