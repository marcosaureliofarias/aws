module EasyCrm
  module EasyContactQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_crm
        alias_method_chain :columns_with_me, :easy_crm
        alias_method_chain :get_custom_sql_for_field, :easy_crm

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_crm
        initialize_available_filters_without_easy_crm

        group = l("label_filter_group_#{EasyCrmCaseQuery.name.underscore}")

        add_available_filter 'easy_crm_cases.easy_crm_case_status_id',
                             {:type => :list, :order => 2, :values => Proc.new do
                               values = EasyCrmCaseStatus.sorted.collect { |s| [s.name, s.id.to_s] }
                               values
                             end,
                              :group => group, :name => EasyCrmCase.human_attribute_name(:easy_crm_case_status), :joins => :easy_crm_cases
                             }

        add_available_filter 'easy_crm_cases.name', { type: :string, order: 3, group: group, name: EasyCrmCase.human_attribute_name(:name), joins: :easy_crm_cases }
        add_principal_autocomplete_filter 'easy_crm_cases.author_id', { klass: User, order: 4, group: group, name: EasyCrmCase.human_attribute_name(:author_id), joins: :easy_crm_cases }
        add_principal_autocomplete_filter 'easy_crm_cases.assigned_to_id', { klass: User, order: 5, group: group, name: EasyCrmCase.human_attribute_name(:account_manager), joins: :easy_crm_cases }
        if EasyUserType.easy_type_partner.any?
          add_principal_autocomplete_filter 'easy_crm_cases.external_assigned_to_id', { klass: User, order: 5, group: group, name: EasyCrmCase.human_attribute_name(:external_account_manager), joins: :easy_crm_cases }
        end
        add_available_filter 'easy_crm_cases.contract_date', {:type => :date_period, :order => 6, :group => group, :name => EasyCrmCase.human_attribute_name(:contract_date), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.next_action', {:type => :date_period, :order => 7, :group => group, :name => EasyCrmCase.human_attribute_name(:next_action), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.price', {:type => :float, :order => 8, :group => group, :name => EasyCrmCase.human_attribute_name(:price), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.need_reaction', {:type => :boolean, :order => 9, :group => group, :name => EasyCrmCase.human_attribute_name(:need_reaction), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.is_canceled', {:type => :boolean, :order => 10, :group => group, :name => EasyCrmCase.human_attribute_name(:is_canceled), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.is_finished', {:type => :boolean, :order => 11, :group => group, :name => EasyCrmCase.human_attribute_name(:is_finished), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.email', {:type => :string, :order => 12, :group => group, :name => EasyCrmCase.human_attribute_name(:email), :joins => :easy_crm_cases}
        add_available_filter 'easy_crm_cases.telephone', {:type => :string, :order => 13, :group => group, :name => EasyCrmCase.human_attribute_name(:telephone), :joins => :easy_crm_cases}

        group = l('label_filter_group_sales_activity_additional_filters')

        EasyEntityActivityCategory.sorted.each_with_index do |category, index|
          add_available_filter "sales_activity_#{category.id}_not_in", {:type => :date_period, :order => index, :group => group, :name => l(:label_filter_sales_activity_not_in, category: category)}
        end

        add_custom_fields_filters(EasyCrmCaseCustomField, :easy_crm_cases)
      end

      def columns_with_me_with_easy_crm
        columns_with_me_without_easy_crm + ['easy_crm_cases.assigned_to_id', 'easy_crm_cases.external_assigned_to_id', 'easy_crm_cases.author_id']
      end

      def get_custom_sql_for_field_with_easy_crm(field, operator, value)
        f = field.to_s
        if /^sales_activity_\d+_not_in$/.match?(f)
          sql_for_sales_activity(field, operator, value)
        else
          get_custom_sql_for_field_without_easy_crm(field, operator, value)
        end
      end

      def sql_for_sales_activity(field, operator, value)
        if field.match /(\d+)/
          category_id = $1
          db_table = 'eea'
          db_field = 'start_time'
          time_statement = sql_for_field(field, operator, value, db_table, db_field)
          sql = "#{EasyContact.table_name}.id NOT IN (SELECT
                                                            eea.entity_id
                                                      FROM  #{EasyEntityActivity.table_name} eea
                                                      WHERE
                                                            eea.entity_type = 'EasyContact' #{time_statement.present? ? 'AND ' + time_statement : ''}
                                                            AND eea.category_id = #{category_id})"

          sql += " AND #{EasyContact.table_name}.id NOT IN (SELECT easy_contact_id
                                                            FROM #{EasyEntityActivity.table_name} eea
                                                                 JOIN
                                                                 #{EasyContactEntityAssignment.table_name} on eea.entity_id = #{EasyContactEntityAssignment.table_name}.entity_id
                                                                 AND #{EasyContactEntityAssignment.table_name}.entity_type = 'EasyCrmCase'
                                                            WHERE
                                                                 eea.entity_type = 'EasyCrmCase' #{time_statement.present? ? 'AND ' + time_statement : ''}
                                                                 AND eea.category_id = #{category_id})"
        end
        sql || '(1=0)'
      end


    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch('EasyContactQuery', 'EasyCrm::EasyContactQueryPatch', :if => Proc.new { Redmine::Plugin.installed?(:easy_contacts) })
