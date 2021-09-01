class EasyCrmCaseQuery < EasyQuery

  def self.entity_css_classes(crm_case, options={})
    user = options[:user] || User.current
    crm_case.css_classes(user, options)
  end

  def initialize_available_filters
    group = default_group_label

    if !self.project
      add_available_filter 'xproject_id', {:type => :list, data_type: :project, :order => 1, :values => Proc.new do
                                          self.all_projects_values(:include_mine => true)
                                        end,
                                           :group => group,
                                           :name => EasyCrmCase.human_attribute_name(:project_id)
                                        }
    end

    add_available_filter 'easy_crm_case_status_id', {:type => :list, :order => 2, :values => Proc.new do
                                                    values = EasyCrmCaseStatus.sorted.collect { |s| [s.name, s.id.to_s] }
                                                    values
                                                  end,
                                                     :group => group, :name => EasyCrmCase.human_attribute_name(:easy_crm_case_status),
                                                     :attr_reader => true,
                                                     :attr_writer => true
                                                  }

    add_available_filter 'name', {:type => :string, :order => 3, :group => group, :name => EasyCrmCase.human_attribute_name(:name), :attr_reader => true, :attr_writer => true}
    add_principal_autocomplete_filter 'author_id', { klass: User, group: group, name: EasyCrmCase.human_attribute_name(:author_id), attr_reader: true, attr_writer: true, order: 4 }
    add_principal_autocomplete_filter 'assigned_to_id', { klass: User, group: group, name: EasyCrmCase.human_attribute_name(:account_manager), attr_reader: true, attr_writer: true, order: 5 }
    if EasyUserType.easy_type_partner.any?
      add_principal_autocomplete_filter 'external_assigned_to_id', { klass: User, group: group, name: EasyCrmCase.human_attribute_name(:external_account_manager), attr_reader: true, attr_writer: true, order: 6 }
    end

    add_available_filter 'currency', {:type => :list, :values => Proc.new do
      EasyCurrency.activated.collect { |c| [c.name, c.iso_code] }
    end,
                                       :group => group, :name => EasyCrmCase.human_attribute_name(:currency)
    } if EasyCurrency.activated.any?

    add_available_filter 'contract_date', {:type => :date_period, :order => 6, :group => group, :name => EasyCrmCase.human_attribute_name(:contract_date)}
    add_available_filter 'next_action', {:type => :date_period, :order => 7, :group => group, :name => EasyCrmCase.human_attribute_name(:next_action)}
    add_available_filter 'price', {:type => :currency, :order => 8, :group => group, :name => EasyCrmCase.human_attribute_name(:price)}
    add_available_filter 'need_reaction', {:type => :boolean, :order => 9, :group => group, :name => EasyCrmCase.human_attribute_name(:need_reaction)}
    add_available_filter 'is_canceled', {:type => :boolean, :order => 10, :group => group, :name => EasyCrmCase.human_attribute_name(:is_canceled), :attr_reader => true, :attr_writer => true}
    add_available_filter 'is_finished', {:type => :boolean, :order => 11, :group => group, :name => EasyCrmCase.human_attribute_name(:is_finished), :attr_reader => true, :attr_writer => true}
    add_available_filter 'email', {:type => :string, :order => 12, :group => group, :name => EasyCrmCase.human_attribute_name(:email)}
    add_available_filter 'telephone', {:type => :string, :order => 13, :group => group, :name => EasyCrmCase.human_attribute_name(:telephone)}
    add_available_filter 'description', {:type => :text, :order => 14, :group => group, :name => EasyCrmCase.human_attribute_name(:description)}
    add_available_filter 'email_cc', {:type => :string, :order => 15, :group => group, :name => EasyCrmCase.human_attribute_name(:email_cc)}
    add_available_filter 'created_at', {:type => :date_period, :time_column => true, :order => 15, :group => group}
    add_available_filter 'updated_at', {:type => :date_period, :time_column => true, :label => :label_updated_within, :group => group}
    add_available_filter 'tags', {:type => :list, :values => Proc.new{all_tags_values}, :label => :label_easy_tags, :group => group}
    add_available_filter 'easy_external_id', { type: :string, :group => group }

    add_available_filter "#{EasyCrmCaseStatus.table_name}.is_closed", {:type => :boolean, :order => 16, :group => group, :name => EasyCrmCaseStatus.human_attribute_name(:is_closed), :joins => :easy_crm_case_status}
    add_available_filter "#{EasyCrmCaseStatus.table_name}.is_won", {:type => :boolean, :order => 17, :group => group, :name => EasyCrmCaseStatus.human_attribute_name(:is_won), :joins => :easy_crm_case_status}
    add_available_filter "#{EasyCrmCaseStatus.table_name}.is_provisioned", { type: :boolean, order: 18, group: group, name: EasyCrmCaseStatus.human_attribute_name(:is_provisioned), joins: :easy_crm_case_status }
    add_available_filter "#{EasyCrmCaseStatus.table_name}.is_paid", {:type => :boolean, :order => 18, :group => group, :name => EasyCrmCaseStatus.human_attribute_name(:is_paid), :joins => :easy_crm_case_status}

    add_custom_fields_filters(EasyCrmCaseCustomField)

    group = l :label_filter_group_easy_entity_activity_crm_case_query

    add_available_filter('easy_entity_activities_existance', {:type => :boolean, :order => 1, :group => group, :name => l(:label_has_entity_activity), :includes => :easy_entity_activities})
    add_available_filter('easy_entity_activities.category_id', {:type => :list, :values => proc { EasyEntityActivityCategory.sorted.collect { |s| [s.name, s.id.to_s] } }, :order => 3, :group => group, :name => l(:enumeration_easy_entity_activity_category), :includes => :easy_entity_activities})
    add_available_filter('easy_entity_activities.is_finished', {:type => :list, :values => [[::I18n.t(:general_text_Yes), '1'], [::I18n.t(:general_text_No), '0']], :order => 4, :group => group, :name => l(:field_easy_entity_activity_finished), :includes => :easy_entity_activities})
    add_available_filter('easy_entity_activities.start_time', {:type => :date_period, :order => 5, :group => group, :name => l(:field_easy_entity_activity_start_time), :includes => :easy_entity_activities})
    add_available_filter('easy_entity_activities.created_at', {:type => :date_period, :order => 6, :group => group, :name => l(:field_created_at), :includes => :easy_entity_activities})
    add_available_filter('easy_entity_activities.updated_at', {:type => :date_period, :order => 7, :group => group, :name => l(:field_updated_at), :includes => :easy_entity_activities})

    group = l(:label_filter_group_easy_crm_contact_query)
    # add_available_filter 'easy_contacts.firstname', {type: :string, order: 2, group: group, name: "#{l(:label_prefix_easy_contacts_query_filter)} #{l(:field_firstname)}"}
    # add_available_filter 'easy_contacts.lastname', {type: :string, order: 3, group: group, name: "#{l(:label_prefix_easy_contacts_query_filter)} #{l(:field_lastname)}"}
    # add_available_filter 'easy_contacts.type_id', {type: :list, order: 4, values: Proc.new {EasyContactType.select([:type_name, :id, :internal_name]).all.collect {|i| [i.name, i.id.to_s]}}, group: group, name: "#{l(:label_prefix_easy_contacts_query_filter)} #{l(:field_type)}"}
    # add_available_filter 'easy_contacts.is_global', {type: :boolean, order: 5, group: group, name: "#{l(:label_prefix_easy_contacts_query_filter)} #{l(:field_is_global)}"}
    add_available_filter 'easy_contacts.id', {type: :list_autocomplete, order: 1, source: 'easy_contacts_visible_contacts', source_root: 'easy_contacts', group: group, name: "#{l(:label_prefix_easy_contacts_query_filter)} #{l(:field_easy_contact)}", assoc: :easy_contacts, klass: EasyContact }

    group = l(:label_easy_crm_case_customer)
    add_available_filter 'main_easy_contact.firstname', {type: :string, order: 2, group: group, name: l(:field_firstname)}
    add_available_filter 'main_easy_contact.lastname', {type: :string, order: 3, group: group, name: l(:field_lastname)}
    add_available_filter 'main_easy_contact.type_id', {type: :list, order: 4, values: Proc.new {EasyContactType.select([:type_name, :id, :internal_name]).all.collect {|i| [i.name, i.id.to_s]}}, group: group, name: l(:field_type)}
    add_available_filter 'main_easy_contact.is_global', {type: :boolean, order: 5, group: group, name: l(:field_is_global)}
    add_available_filter 'main_easy_contact_id', {type: :list_autocomplete, order: 1, source: 'easy_contacts_visible_contacts', source_root: 'easy_contacts', group: group, name: l(:field_easy_contact)}

    add_custom_fields_filters(EasyContactCustomField, :main_easy_contact, dont_use_assoc_filter_name: true, group_name: l(:label_easy_crm_case_customer_query_group_custom_fields))
    add_custom_fields_filters(EasyContactCustomField, :easy_contacts, group_name: l(:label_filter_group_easy_crm_contact_query_custom_fields))

    group = l('label_filter_group_sales_activity_additional_filters')
    EasyEntityActivityCategory.sorted.each_with_index do |category, index|
      add_available_filter "sales_activity_#{category.id}_not_in", {:type => :date_period, :order => index, :group => group, :name => l(:label_filter_sales_activity_not_in, category: category)}
    end

    add_associations_custom_fields_filters :project
  end

  def initialize_available_columns
    group = default_group_label

    add_available_column EasyQueryColumn.new(:project, :title => EasyCrmCase.human_attribute_name(:project), :sortable => "#{Project.table_name}.name", :includes => [:project], :groupable => "#{EasyCrmCase.table_name}.project_id", :group => group)
    add_available_column EasyQueryColumn.new(:easy_crm_case_status, :title => EasyCrmCase.human_attribute_name(:easy_crm_case_status), :sortable => "#{EasyCrmCaseStatus.table_name}.position", :groupable => true, :includes => [:easy_crm_case_status], :group => group)
    add_available_column EasyQueryColumn.new(:name, :title => EasyCrmCase.human_attribute_name(:name), :sortable => "#{EasyCrmCase.table_name}.name", :group => group)
    add_available_column EasyQueryColumn.new(:description, :title => EasyCrmCase.human_attribute_name(:description), :inline => false, :group => group)
    add_available_column EasyQueryDateColumn.new(:contract_date, :title => EasyCrmCase.human_attribute_name(:contract_date), :sortable => "#{EasyCrmCase.table_name}.contract_date", :groupable => "#{EasyCrmCase.table_name}.contract_date", :group => group)
    add_available_column EasyQueryDateColumn.new(:next_action, :title => EasyCrmCase.human_attribute_name(:next_action), :sortable => "#{EasyCrmCase.table_name}.next_action", :groupable => "#{EasyCrmCase.table_name}.next_action", :group => group)
    add_available_column EasyQueryDateColumn.new(:created_at, :title => EasyCrmCase.human_attribute_name(:created_at), :sortable => "#{EasyCrmCase.table_name}.created_at", :groupable => "#{EasyCrmCase.table_name}.created_at", :group => group)
    add_available_column EasyQueryDateColumn.new(:updated_at, :title => EasyCrmCase.human_attribute_name(:updated_at), :sortable => "#{EasyCrmCase.table_name}.updated_at", :groupable => true, :group => group)
    add_available_column EasyQueryDateColumn.new(:closed_on, :sortable => "#{EasyCrmCase.table_name}.closed_on", :group => group)
    add_available_column EasyQueryColumn.new(:easy_last_updated_by, :sortable => lambda { User.fields_for_order_statement('last_updator') }, :groupable => "#{EasyCrmCase.table_name}.easy_last_updated_by_id", :preload => [:easy_last_updated_by => :easy_avatar], :group => group)
    add_available_column EasyQueryColumn.new(:easy_closed_by, :groupable => "#{EasyCrmCase.table_name}.easy_closed_by_id", :sortable => lambda { User.fields_for_order_statement('closed_by_users') }, :preload => [:easy_closed_by => :easy_avatar], :group => group)
    add_available_column EasyQueryColumn.new(:email, :title => EasyCrmCase.human_attribute_name(:email), :sortable => "#{EasyCrmCase.table_name}.email", :group => group)
    add_available_column EasyQueryColumn.new(:email_cc, :title => EasyCrmCase.human_attribute_name(:email_cc), :sortable => "#{EasyCrmCase.table_name}.email_cc", :group => group)
    add_available_column EasyQueryColumn.new(:telephone, :title => EasyCrmCase.human_attribute_name(:telephone), :sortable => "#{EasyCrmCase.table_name}.telephone", :group => group)
    add_available_column EasyQueryCurrencyColumn.new(:price, :title => EasyCrmCase.human_attribute_name(:price), :sortable => "#{EasyCrmCase.table_name}.price", :sumable => :both, :group => group, query: self, sumable_options: {model: 'EasyCrmCase', column: 'price', distinct_columns: [["#{EasyCrmCase.table_name}.id", :easy_crm_case]]})
    add_available_column EasyQueryColumn.new(:need_reaction, :title => EasyCrmCase.human_attribute_name(:need_reaction), :sortable => "#{EasyCrmCase.table_name}.need_reaction", :group => group)

    add_available_column EasyQueryColumn.new(:author, :title => EasyCrmCase.human_attribute_name(:author_id), :sortable => lambda { User.fields_for_order_statement('case_authors') }, :groupable => "#{EasyCrmCase.table_name}.author_id", :preload => [:author => :easy_avatar], :group => group)
    add_available_column EasyQueryColumn.new(:assigned_to, :title => EasyCrmCase.human_attribute_name(:account_manager), :sortable => lambda { User.fields_for_order_statement('case_assigned_to') }, :groupable => "#{EasyCrmCase.table_name}.assigned_to_id", :preload => [:assigned_to => :easy_avatar], :group => group)
    if EasyUserType.easy_type_partner.any?
      add_available_column EasyQueryColumn.new(:external_assigned_to, :title => EasyCrmCase.human_attribute_name(:external_account_manager), :sortable => lambda { User.fields_for_order_statement('case_external_assigned_to') }, :groupable => "#{EasyCrmCase.table_name}.external_assigned_to_id", :preload => [:external_assigned_to => :easy_avatar], :group => group)
    end
    add_available_column EasyQueryColumn.new(:tags, :preload => [:tags], :caption => :label_easy_tags, :group => group)

    add_available_column EasyQueryColumn.new(:easy_external_id, caption: :field_easy_external,  group: group)

    add_available_column EasyQueryColumn.new(:easy_entity_activities, :caption => :label_easy_entity_activity, :preload => [easy_entity_activities: :category], :group => group)
    add_available_column EasyQueryColumn.new(:currency, title: EasyCrmCase.human_attribute_name(:currency), group: group)

    add_available_columns EasyCrmCaseCustomField.sorted.visible.collect { |cf| EasyQueryCustomFieldColumn.new(cf)}

    add_associated_columns EasyContactQuery, association_name: :main_easy_contact, group_name: l(:label_easy_crm_case_customer)
    add_associated_columns EasyContactQuery, association_name: :easy_contacts
    add_associated_columns EasyUserQuery, association_name: :assigned_to, group_name: EasyCrmCase.human_attribute_name(:account_manager), is_groupable: false
    add_associated_columns EasyUserQuery, association_name: :external_assigned_to, group_name: EasyCrmCase.human_attribute_name(:external_account_manager), is_groupable: false
  end

  def self.permission_view_entities
    :view_easy_crms
  end

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
  end

  def entity_easy_query_path(options = {})
    if options.delete(:kanban)
      easy_crm_kanban_project_path(options.delete(:project) || self.project, options)
    else
      super
    end
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = project_statement.presence
      @additional_statement_added = true
    end
    @additional_statement
  end

  def project_statement
    return nil if !self.project

    if self.project && (force_current_project_filter || !EasySetting.value('easy_crm_case_query_includes_descendants', project))
      "#{EasyCrmCase.table_name}.project_id = #{self.project_id}"
    elsif self.project
      # EasySetting.value('easy_crm_case_query_includes_descendants', project) has to be true here
      project_clauses = []
      if self.project && !self.project.descendants.active_and_planned.empty?
        ids = [self.project.id]
        if self.has_filter?('subproject_id')
          case self.operator_for('subproject_id')
            when '='
              # include the selected subprojects
              if (values = self.values_for('subproject_id').select(&:present?).collect(&:to_i)).present?
                ids = values
              end
            when '!*'
              # main project only
            else
              # all subprojects
              ids.concat(self.project.descendants.pluck(:id))
          end
        elsif Setting.display_subprojects_issues?
          if self.project.easy_is_easy_template?
            ids.concat(self.project.descendants.templates.pluck(:id))
          else
            ids.concat(self.project.descendants.non_templates.pluck(:id))
          end
        end
        project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
      elsif self.project
        project_clauses << "#{Project.table_name}.id = %d" % self.project.id
      elsif !self.project
        project_clauses << "#{Project.table_name}.easy_is_easy_template=#{self.class.connection.quoted_false}"
        if self.has_filter?('is_planned') && self.values_for('is_planned').size == 1
          planned_val = value_for('is_planned').to_s.to_boolean
          planned_val = !planned_val if operator_for('is_planned') == '!='
          project_clauses << "#{Project.table_name}.status #{planned_val ? '=' : '!='} #{Project::STATUS_PLANNED}"
        end
      end
      project_clauses.any? ? project_clauses.join(' AND ') : nil
    else
      "#{Project.table_name}.easy_is_easy_template=#{self.class.connection.quoted_false}"
    end

  end

  def searchable_columns
    ["#{EasyCrmCase.table_name}.name", "#{EasyCrmCase.table_name}.email", "#{EasyCrmCase.table_name}.telephone"]
  end

  def entity
    EasyCrmCase
  end

  def entity_context_menu_path(options = {})
    context_menu_easy_crm_cases_path({:project_id => self.project}.merge(options))
  end

  def self.chart_support?
    true
  end

  def columns_with_me
    super + ['external_assigned_to_id']
  end

  def extended_period_options
    {
      :extended_options => [:to_today, :is_null, :is_not_null, :from_tomorrow],
      :option_limit => {
          :after_due_date => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_week => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :tomorrow => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_7_days => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_14_days => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_15_days => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_30_days => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_90_days => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_month => ['contract_date', 'next_action', 'created_at', 'updated_at'],
          :next_year => ['contract_date', 'next_action', 'created_at', 'updated_at']
      },
      :field_disabled_options => {
        'not_updated_on' => [:is_null, :is_not_null]
      }
    }
  end

  def add_additional_order_statement_joins(order_options)
    sql = []
    if order_options.present?
      if order_options.include?('case_authors')
        sql << "LEFT OUTER JOIN #{User.quoted_table_name} case_authors ON case_authors.id = #{self.entity.quoted_table_name}.author_id"
      end
      if order_options.include?('case_assigned_to')
        sql << "LEFT OUTER JOIN #{User.quoted_table_name} case_assigned_to ON case_assigned_to.id = #{self.entity.quoted_table_name}.assigned_to_id"
      end
      if order_options.include?('case_external_assigned_to')
        sql << "LEFT OUTER JOIN #{User.quoted_table_name} case_external_assigned_to ON case_external_assigned_to.id = #{self.entity.quoted_table_name}.assigned_to_id"
      end
      if order_options.include?('last_updator') && col = available_columns.detect { |col| (col.name == :easy_last_updated_by) }
        sql << joins_for_easy_last_updated_by_field
      end
      if order_options.include?('closed_by_users')
        sql << "LEFT OUTER JOIN #{User.table_name} closed_by_users ON closed_by_users.id = #{EasyCrmCase.table_name}.easy_closed_by_id"
      end
    end
    sql
  end

  def sql_for_xproject_id_field(field, operator, v)
    db_table = self.entity.table_name
    db_field = 'project_id'
    returned_sql_for_field = self.sql_for_field(field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') if returned_sql_for_field.present?
  end

  def sql_for_easy_entity_activities_existance_field(_field, operator, value)
    "#{EasyEntityActivity.table_name}.id is #{(Array(value).include?('0')) ? '' : 'NOT '} NULL"
  end

  def get_custom_sql_for_field(field, operator, value)
    case field.to_s
    when /^sales_activity_\d+_not_in$/
      sql_for_sales_activity(field, operator, value)
    when /main_easy_contact\./
      sql_for_main_easy_contact_field(field, operator, value)
    when /easy_contacts\.id/
      sql_for_easy_contacts_field(field, operator, value)
    else
      super(field, operator, value)
    end
  end

  def sql_for_main_easy_contact_field(field, operator, value)
    db_not = ['!*', '!', '!~'].include?(operator) ? 'NOT ' : ''
    field_name = field.split('.').last
    scope = EasyContact.where("#{EasyCrmCase.table_name}.main_easy_contact_id = easy_contacts.id")
    scope = scope.where(sql_for_field(field, operator.tr('!', '').presence || '=', value, 'easy_contacts', field_name)) #if ['!', '=', '~'].include?(operator)
    "#{db_not} EXISTS (#{scope.to_sql})"
  end

  def sql_for_easy_contacts_field(field, operator, value)
    db_not = ['!*', '!', '!~'].include?(operator) ? 'NOT IN' : 'IN'
    if ['=', '!'].include?(operator)
      "#{EasyCrmCase.table_name}.id #{db_not} (SELECT entity_id FROM easy_contact_entity_assignments WHERE entity_type = 'EasyCrmCase' AND easy_contact_id IN (#{value.join(',')}))"
    else
      "#{EasyCrmCase.table_name}.id #{db_not} (SELECT entity_id FROM easy_contact_entity_assignments WHERE entity_type = 'EasyCrmCase')"
    end
  end

  def sql_for_sales_activity(field, operator, value)
    if field.match /(\d+)/
      category_id = $1
      db_table = 'eea'
      db_field = 'start_time'
      time_statement = sql_for_field(field, operator, value, db_table, db_field)
      sql = "#{EasyCrmCase.table_name}.id NOT IN (SELECT eea.entity_id FROM #{EasyEntityActivity.table_name} eea WHERE eea.entity_type = 'EasyCrmCase' #{time_statement.present? ? 'AND ' + time_statement : ''} AND eea.category_id = #{category_id})"
    end
    sql ||= '(1=0)'
  end

  def joins_for_easy_last_updated_by_field
    main_entity = entity.arel_table
    user = User.arel_table.alias('last_updator')
    join_users = main_entity.create_on(main_entity[:easy_last_updated_by_id].eq(user[:id]))

    main_entity.create_join(user, join_users, Arel::Nodes::InnerJoin).to_sql
  end

end
