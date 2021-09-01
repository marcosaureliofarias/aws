class EasyMoneyGenericQuery < EasyQuery

  attr_accessor :entity_to_statement

  def self.permission_view_entities
    :view_easy_money
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'spent_on', { type: :date_period, order: 3 }
      add_available_filter 'name', { type: :string, order: 4 }
      add_available_filter 'description', { type: :text, order: 5 }
      add_available_filter 'price1', { type: :float, order: 6 }
      add_available_filter 'price2', { type: :float, order: 7 }
      add_available_filter 'vat', { type: :float, order: 8 }
      add_available_filter 'version_id', { type: :list_optional, values: Proc.new { Version.values_for_select_with_project(Version.visible.joins(:project)) } }
      add_available_filter 'tags', { type: :list_autocomplete, label: :label_easy_tags, source: 'tags', source_root: '' }
      add_available_filter 'entity_type', { type: :list, values: Proc.new { all_entity_type_values }, label: :field_entity }
    end

    on_filter_group(l(:label_filter_group_easy_money_project_cache_query)) do
      if project
        unless project.leaf?
          subprojects = if project.easy_is_easy_template
                          Proc.new { project.descendants.visible.templates.pluck(:name, :id) }
                        else
                          Proc.new { project.descendants.visible.non_templates.pluck(:name, :id) }
                        end
          add_available_filter 'subproject_id', { :type => :list_subprojects, :order => 2, :values => subprojects, :data_type => :project }
        end
      else
        add_available_filter 'project', { :type => :list, :order => 1, :values => Proc.new{self.projects_for_select(Project.visible.non_templates.has_module(:easy_money))}, :data_type => :project }
        add_available_filter 'parent_id', { :type => :list_optional, :order => 2, :values => Proc.new{self.all_projects_parents_values}, :data_type => :project }
        add_available_filter 'main_project', { :type => :list_optional, :order => 3, :values => Proc.new{self.all_main_projects_values}, :data_type => :project }
        add_available_filter 'is_project_closed', { :type => :boolean, :order => 4, :name => l(:field_is_project_closed) }
      end
    end

    if self.entity_custom_field
      add_custom_fields_filters(self.entity_custom_field)
    end

    add_associations_custom_fields_filters :project
  end

  def initialize_available_columns
    project_group = l(:label_filter_group_easy_project_query)


    add_available_column :project, sortable: "#{Project.table_name}.name", groupable: "#{Project.table_name}.id", group: project_group
    add_available_column :main_project, group: project_group
    add_available_column :issue, group: project_group
    add_available_column :version, group: project_group

    group = default_group_label

    add_available_column EasyQueryDateColumn.new(:spent_on, sortable: "#{entity_table_name}.spent_on", groupable: "#{entity_table_name}.spent_on", group: group)
    add_available_column :name, sortable: "#{entity_table_name}.name", groupable: "#{entity_table_name}.name", group: group
    add_available_column :description, sortable: "#{entity_table_name}.description", groupable: "#{entity_table_name}.description", group: group
    add_available_column EasyQueryCurrencyColumn.new(:price1, sortable: "#{entity_table_name}.price1", sumable: :both, group: group, query: self)
    add_available_column EasyQueryCurrencyColumn.new(:price2, sortable: "#{entity_table_name}.price2", sumable: :both, group: group, query: self)
    add_available_column :vat, sortable: "#{entity_table_name}.vat", groupable: "#{entity_table_name}.vat", group: group, query: self
    add_available_column :entity_title, title: l(:field_entity), groupable: "COALESCE(CONCAT(#{entity_table_name}.entity_type, '_', #{entity_table_name}.entity_id), '_')", group: group, query: self

    add_available_column :tags, caption: :label_easy_tags, preload: [:tags], group: group
    add_available_column :attachments, preload: [:attachments], group: group

    if entity_custom_field
      entity_custom_field.all.each do |custom_field|
        add_available_column EasyQueryCustomFieldColumn.new(custom_field)
      end
    end

    project_cf_group = l(:label_project_custom_fields)
    ProjectCustomField.visible.where(show_on_list: true).sorted.each do |custom_field|
      add_available_column EasyQueryCustomFieldColumn.new(custom_field, assoc: :project, group: project_cf_group)
    end
  end

  def additional_statement
    unless @additional_statement_added
      sql = project_statement
      @additional_statement = sql unless sql.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def searchable_columns
    ["#{self.entity.table_name}.name"]
  end

  def entity_custom_field
  end

  def statement_skip_fields
    ['subproject_id']
  end

  def default_find_include
    [:project]
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['spent_on', 'desc']]
  end

  def entity_easy_query_path(options)
    polymorphic_path([self.project, self.entity], options)
  end

  def all_entity_type_values
    values = [
      [l(:field_project), 'Project'],
      [l(:field_issue), 'Issue']
    ]
    values << [l(:label_easy_crm_case), 'EasyCrmCase'] if Redmine::Plugin.installed?(:easy_crm)
    values
  end

  def self.chart_support?
    true
  end

  def project_statement(project_table=Project.table_name)
    project_clauses = []
    descendants = self.project.descendants.active_and_planned.has_module(:easy_money) if self.project
    if self.project && !descendants.empty?
      ids = [self.project.id]
      if self.has_filter?('subproject_id')
        case self.operator_for('subproject_id')
        when '='
          # include the selected subprojects
          if (values = self.values_for('subproject_id').select(&:present?).collect(&:to_i)).present?
            ids = descendants.where(id: values).pluck(:id)
          end
        when '!*'
          # main project only
        else
          # all subprojects
          ids.concat(descendants.pluck(:id))
        end
      elsif self.project.easy_money_settings.try(:include_childs?)
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

  def add_statement_sql_before_filters
    where = []
    if self.entity_to_statement
      case self.entity_to_statement.class.name
      when 'Project'
        sql_where = []

        if project && project.easy_money_settings.try(:include_childs?)
          sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Project' AND p.lft >= #{self.entity_to_statement.lft} AND p.rgt <= #{self.entity_to_statement.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
          sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Issue' AND p.lft >= #{self.entity_to_statement.lft} AND p.rgt <= #{self.entity_to_statement.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
        else
          sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Project' AND p.id = #{self.entity_to_statement.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
          sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Issue' AND p.id = #{self.entity_to_statement.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
        end

        sql_where << "EXISTS (
SELECT v.id
FROM #{Version.table_name} v
WHERE v.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Version' AND v.project_id = #{self.entity_to_statement.id})"

        where << '(' + sql_where.join(' OR ') + ')'
      when 'Issue'
        where << "EXISTS (SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{self.entity.table_name}.entity_id AND #{self.entity.table_name}.entity_type = 'Issue' AND i.root_id = #{self.entity_to_statement.root_id} AND i.lft >= #{self.entity_to_statement.lft} AND i.rgt <= #{self.entity_to_statement.rgt})"
      when 'Version'
        where <<  "#{self.entity.table_name}.entity_type = 'Version' AND #{self.entity.table_name}.entity_id = #{self.entity_to_statement.id}"
      else
        where << "#{self.entity.table_name}.entity_type = '#{self.class.connection.quote_string(self.entity_to_statement.class.name)}' AND #{self.entity.table_name}.entity_id = #{self.entity_to_statement.id}"
      end
    end
    where.join(' AND ') unless where.blank?
  end

  def sql_for_project_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + [*value].collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 WHERE #{self.entity.table_name}.entity_id = p1.id AND p1.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 LEFT OUTER JOIN #{Project.table_name} p1 ON i1.project_id = p1.id WHERE #{self.entity.table_name}.entity_id = i1.id AND i1.project_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 WHERE #{self.entity.table_name}.entity_id = v1.id AND v1.project_id #{sql_value})
    END"
  end

  def sql_for_main_project_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 INNER JOIN #{Project.table_name} p2 ON p2.lft >= p1.lft AND p2.rgt <= p1.rgt WHERE #{self.entity.table_name}.entity_id = p2.id AND p1.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 INNER JOIN #{Project.table_name} p1 ON p1.id = i1.project_id INNER JOIN #{Project.table_name} p2 ON p2.lft <= p1.lft AND p2.rgt >= p1.rgt AND p2.parent_id IS NULL WHERE #{self.entity.table_name}.entity_id = i1.id AND p2.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 INNER JOIN #{Project.table_name} p1 ON p1.id = v1.project_id INNER JOIN #{Project.table_name} p2 ON p2.lft <= p1.lft AND p2.rgt >= p1.rgt AND p2.parent_id IS NULL WHERE #{self.entity.table_name}.entity_id = v1.id AND p2.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
    END"
  end

  def sql_for_version_id_field(field, operator, value)
    case operator
    when '*', '!*'
      e = (operator == '*' ? 'EXISTS' : 'NOT EXISTS')
      "#{e}(SELECT v1.id FROM #{Version.table_name} v1 WHERE #{self.entity.table_name}.entity_id = v1.id AND #{self.entity.table_name}.entity_type = 'Version')"
    when '=', '!'
      sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")"
      "EXISTS(SELECT v1.id FROM #{Version.table_name} v1 WHERE #{self.entity.table_name}.entity_id = v1.id AND #{self.entity.table_name}.entity_id #{sql_value})"
    end
  end

  def sql_for_parent_id_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 WHERE #{self.entity.table_name}.entity_id = p1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 INNER JOIN #{Project.table_name} p1 ON p1.id = i1.project_id WHERE #{self.entity.table_name}.entity_id = i1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 INNER JOIN #{Project.table_name} p1 ON p1.id = v1.project_id WHERE #{self.entity.table_name}.entity_id = v1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
    END"
  end

  def sql_for_is_project_closed_field(field, operator, value)
    o = value.first == '1' ? '=' : '<>'
    "(#{Project.table_name}.status #{o} #{Project::STATUS_CLOSED})"
  end

  def easy_currency_code
    read_attribute(:easy_currency_code) || default_easy_currency_code
  end

  def default_easy_currency_code
    @default_easy_currency_code ||= project.try(:easy_currency_code) || EasyCurrency.default_code
  end

end
