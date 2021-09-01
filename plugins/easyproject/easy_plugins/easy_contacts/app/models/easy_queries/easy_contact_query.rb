class EasyContactQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_contacts
  end

  def query_after_initialize
    super
    self.export_formats[:vcf] = { caption: 'vCard' }
    self.export_formats[:atom] = { url: { key: User.current.rss_key } }
  end

  def initialize_available_filters
    group = default_group_label
    add_available_filter 'xproject_id', { type: :list_optional, order: 1, values: Proc.new { projects_for_select_with_current }, group: group }
    add_available_filter 'firstname', { type: :text, order: 2, group: group, name: l(:field_firstname), permitted: EasyContact.firstname_field_visible? }
    add_available_filter 'lastname', { type: :text, order: 3, group: group, name: l(:field_lastname), permitted: EasyContact.lastname_field_visible? }
    add_available_filter 'type_id', { type: :list, order: 4, values: Proc.new { EasyContactType.select([:type_name, :id, :internal_name]).all.collect { |i| [i.name, i.id.to_s] } }, group: group, name: l(:field_type) }
    add_available_filter 'is_global', { type: :boolean, order: 5, group: group, name: l(:field_is_global) }
    add_available_filter 'easy_contacts_group_assignments.group_id', { type: :list_optional, order: 6, values: Proc.new { EasyContactGroup.where("(entity_id = #{User.current.id} AND entity_type = 'Principal') OR ( entity_id IS NULL)").order(:group_name).collect { |c| [c.name, c.id.to_s] } }, includes: [:easy_contact_groups], group: group, name: l(:field_easy_contact_group) }
    add_available_filter 'tags', { type: :list, values: Proc.new { all_tags_values }, label: :label_easy_tags, group: group }
    add_available_filter 'eu_member', { type: :boolean, order: 10, group: group, name: l(:field_easy_contact_from_eu) }
    add_available_filter 'created_on', { type: :date_period, order: 8, group: group, permitted: EasyContact.created_on_field_visible? }
    add_available_filter 'updated_on', { type: :date_period, order: 9, group: group, permitted: EasyContact.updated_on_field_visible? }
    add_principal_autocomplete_filter 'assigned_to_id', { group: group, name: EasyContact.human_attribute_name(:account_manager), permitted: EasyContact.assigned_to_id_field_visible? }
    if EasyUserType.easy_type_partner.any?
      add_principal_autocomplete_filter 'external_assigned_to_id', { group: group, name: EasyContact.human_attribute_name(:external_account_manager), permitted: EasyContact.external_assigned_to_id_field_visible? }
    end
    add_principal_autocomplete_filter 'author_id', { group: group, name: EasyContact.human_attribute_name(:author_id), permitted: EasyContact.author_id_field_visible? }
    add_available_filter 'child', { type: :list_autocomplete, source: 'easy_contacts_with_parents', source_root: 'entities', group: group, label: :label_easy_contact_sub_contact }
    add_available_filter 'parent_id', { type: :list_autocomplete, source: 'easy_contacts_with_children', source_root: 'entities', group: group, label: :field_easy_contacts_parent, visible: EasyContact.parent_id_field_visible? }
    add_available_filter 'root_id', { type: :list_autocomplete, source: 'root_easy_contacts', source_root: 'entities', group: group, label: :label_easy_contact_root_contact }
    add_available_filter 'easy_external_id', { type: :string }
    add_available_filter 'guid', { type: :string, name: l(:field_easy_contact_guid) }

    add_custom_fields_filters(EasyContactCustomField)
  end

  def initialize_available_columns
    group = default_group_label

    tbl = EasyContact.table_name
    add_available_column EasyQueryColumn.new(:id, sortable: "#{tbl}.id", group: group)
    add_available_column EasyQueryColumn.new(:contact_name, caption: :label_easy_contacts_name, sortable: "#{tbl}.firstname", group: group, permitted: EasyContact.firstname_field_visible? && EasyContact.lastname_field_visible?)
    add_available_column EasyQueryColumn.new(:firstname, sortable: "#{tbl}.firstname", group: group, permitted: EasyContact.firstname_field_visible?)
    add_available_column EasyQueryColumn.new(:lastname, sortable: "#{tbl}.lastname", group: group, permitted: EasyContact.lastname_field_visible?)
    add_available_column EasyQueryColumn.new(:parent, sortable: ["#{tbl}.root_id", "#{tbl}.lft", 'parents_contacts_sort.lastname'], default_order: 'desc', groupable: "#{tbl}.parent_id", caption: :field_easy_contacts_parent, preload: [:parent], group: group, permitted: EasyContact.parent_id_field_visible?)
    add_available_column EasyQueryColumn.new(:contact_groups, groupable: "#{EasyContactGroup.table_name}.group_name", includes: [:easy_contact_groups], group: group)
    add_available_column EasyQueryColumn.new(:is_global, groupable: true, sortable: "#{tbl}.is_global", group: group)
    add_available_column EasyQueryColumn.new(:easy_contact_type, includes: [:easy_contact_type], groupable: "#{EasyContactType.table_name}.id", sortable: "#{EasyContactType.table_name}.type_name", group: group)
    add_available_column EasyQueryDateColumn.new(:created_on, sortable: "#{tbl}.created_on", groupable: true, group: group, permitted: EasyContact.created_on_field_visible?)
    add_available_column EasyQueryDateColumn.new(:updated_on, sortable: "#{tbl}.updated_on", groupable: true, group: group, permitted: EasyContact.updated_on_field_visible?)

    add_available_column EasyQueryColumn.new(:assigned_to, title: EasyContact.human_attribute_name(:account_manager), sortable: lambda { User.fields_for_order_statement }, groupable: "#{tbl}.assigned_to_id", includes: [:assigned_to], group: group, permitted: EasyContact.assigned_to_id_field_visible?)
    if EasyUserType.easy_type_partner.any?
      add_available_column EasyQueryColumn.new(:external_assigned_to, title: EasyContact.human_attribute_name(:external_account_manager), sortable: lambda { User.fields_for_order_statement }, groupable: "#{tbl}.external_assigned_to_id", includes: [:external_assigned_to], group: group, permitted: EasyContact.external_assigned_to_id_field_visible?)
    end
    add_available_column EasyQueryColumn.new(:author, title: EasyContact.human_attribute_name(:author_id), sortable: lambda { User.fields_for_order_statement }, groupable: "#{tbl}.author_id", includes: [:author], group: group, permitted: EasyContact.author_id_field_visible?)

    add_available_column EasyQueryColumn.new(:tags, preload: [:tags], caption: :label_easy_tags, group: group)
    add_available_column EasyQueryColumn.new(:easy_external_id, caption: :field_easy_external,  group: group)
    add_available_column EasyQueryColumn.new(:guid, caption: :field_easy_contact_guid,  group: group)

    add_available_columns EasyContactCustomField.visible.sorted.collect { |cf| EasyQueryCustomFieldColumn.new(cf) }
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options.include?('parents_contacts_sort')
      joins << "LEFT OUTER JOIN #{EasyContact.table_name} parents_contacts_sort ON #{EasyContact.table_name}.parent_id = parents_contacts_sort.id"
    end
    return joins
  end

  def searchable_columns
    id_column = "#{EasyContact.table_name}.id"
    id_column = "CAST(#{id_column} AS TEXT)" if Redmine::Database.postgresql?
    ["#{EasyContact.table_name}.firstname", "#{EasyContact.table_name}.lastname", id_column]
  end

  def entity
    EasyContact
  end

  def self.chart_support?
    true
  end

  def get_custom_sql_for_field(field, operator, value)
    if field == 'project_groups'
      db_table = 'easy_contacts_group_assignments'
      sql = "#{EasyContact.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.contact_id FROM #{db_table} WHERE #{db_table}.group_id IN (SELECT #{EasyContactGroup.table_name}.id FROM #{EasyContactGroup.table_name} WHERE #{EasyContactGroup.table_name}.entity_id = #{value} AND #{EasyContactGroup.table_name}.entity_type = 'Project' ) ) "
      return sql
    end
    if field == 'easy_contact_group_id'
      db_table = 'easy_contacts_group_assignments'
      groups = case operator
               when '=', '!' then
                 "IN ('#{Array(value).join("','")}')"
               when '*', '!*' then
                 'IS NOT NULL'
               end

      op = case operator
           when '=', '*' then
             'IN'
           when '!', '!*' then
             'NOT IN'
           end

      sql = "#{EasyContact.table_name}.id #{op} (SELECT #{db_table}.contact_id FROM #{db_table} WHERE #{db_table}.group_id #{groups}) "
      return sql
    end
  end

  def default_find_include
    [:easy_contact_type]
  end

  def default_find_preload
    if outputs.include?('list')
      [:custom_values]
    else
      super
    end
  end

  def preloads_for_entities(contacts)
    if contacts.any? && outputs.include?('list')
      if project
        project_assignments = EasyContactEntityAssignment.where(easy_contact_id: contacts, entity_type: 'Project', entity_id: project).group(:easy_contact_id).pluck(:easy_contact_id)
      end
      principal_assignments = EasyContactEntityAssignment.where(easy_contact_id: contacts, entity_type: 'Principal', entity_id: User.current.id).group(:easy_contact_id).pluck(:easy_contact_id)

      contacts.each do |contact|
        if project
          contact.instance_variable_set "@project_assignement", project_assignments.include?(contact.id)
        end
        contact.instance_variable_set "@principal_assignement", principal_assignments.include?(contact.id)
      end
    end
  end

  def entities(options = {})
    e = super(options)
    preloads_for_entities(e)
    e
  end

  def entities_for_group(group, options = {})
    e = super
    preloads_for_entities(e)
    e
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['firstname', 'asc']]
  end

  def columns_with_me
    super + ['external_assigned_to_id']
  end

  def statement_for_searching
    columns = self.searchable_columns

    token_clauses = columns.collect { |column| "(#{Redmine::Database.like(column, '?')})" }

    if !self.entity.reflect_on_association(:custom_values).nil?
      searchable_custom_field_ids = CustomField.where(type: "#{self.entity}CustomField", searchable: true).pluck(:id)
      if searchable_custom_field_ids.any?
        customized_type = "#{self.entity}CustomField".constantize.customized_class.name
        custom_field_sql = "#{self.entity.table_name}.id IN (SELECT customized_id FROM #{CustomValue.table_name}" +
          " WHERE customized_type='#{customized_type}' AND #{Redmine::Database.like('value', '?')}" +
          " AND #{CustomValue.table_name}.custom_field_id IN (#{searchable_custom_field_ids.join(',')}))"
        token_clauses << custom_field_sql
      end
    end

    token_clauses
  end

  def sql_for_xproject_id_field(field, operator, value)
    db_table = EasyContactEntityAssignment.table_name
    db_field = 'entity_id'
    sql = "#{EasyContact.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.easy_contact_id FROM #{db_table} WHERE #{db_table}.entity_type='Project' AND "
    sql << sql_for_field(field, '=', value, db_table, db_field) + ')'
    return sql
  end

  def sql_for_eu_member_field(field, operator, value)
    sql_for_custom_field("cf_#{EasyContacts::CustomFields.country_id}", value[0] == '0' ? '!' : '=', ISO3166::Country.find_all_by(:in_eu?, true).keys, EasyContacts::CustomFields.country_id)
  end

  def sql_for_child_field(field, operator, value)
    case operator
    when '=', '!'
      parent_ids = EasyContact.where(id: value).distinct.pluck(:parent_id)
      if parent_ids.any?
        "#{EasyContact.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (#{parent_ids.join(',')})"
      end
    when '*', '!*'
      "#{EasyContact.table_name}.rgt - #{EasyContact.table_name}.lft #{ operator == '*' ? '>' : '=' } 1"
    end
  end

  def projects_for_select_with_current
    project_values = self.projects_for_select(Project.where(id: EasyContactEntityAssignment.where(entity_type: 'Project').select(:entity_id)))
    project ? project_values.unshift(["<< #{l(:label_current)} >>", 'current']) : project_values
  end

end
