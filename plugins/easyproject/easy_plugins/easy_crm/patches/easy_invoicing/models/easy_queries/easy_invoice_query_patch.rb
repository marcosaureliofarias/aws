module EasyCrm
  module EasyInvoiceQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize_available_columns, :easy_crm
        alias_method_chain :initialize_available_filters, :easy_crm
        alias_method_chain :columns_with_me, :easy_crm

        def sql_for_is_easy_crm_case_associated_field(field, operator, value)
          "#{(Array(value).include?('1')) ? '' : 'NOT '}EXISTS (SELECT eea.entity_to_id FROM #{EasyEntityAssignment.table_name} eea WHERE eea.entity_from_type = 'EasyInvoiceDocument' AND eea.entity_from_id = #{EasyInvoice.table_name}.id AND eea.entity_to_type = '#{EasyCrmCase.name}')"
        end

        def sql_for_easy_crm_cases_contacts_type_field(field, operator, value)
          scope = EasyContactEntityAssignment.joins(:easy_contact).where(entity_type: 'EasyCrmCase').where(easy_contacts:{type_id: value}).select(:entity_id)
          scope = EasyEntityAssignment.where(entity_from_type: 'EasyInvoiceDocument', entity_to_type: 'EasyCrmCase', entity_to_id: scope).select(:entity_from_id)

          "easy_invoices.id #{ operator == '=' ? 'IN' : 'NOT IN' } (#{scope.to_sql})"
        end
      end
    end

    module InstanceMethods

      def initialize_available_columns_with_easy_crm
        initialize_available_columns_without_easy_crm

        group = l('label_filter_group_easy_crm_case_item_query')
        @available_columns << EasyQueryColumn.new(:easy_crm_case, :sortable => "#{EasyCrmCase.table_name}.name", :includes => [:easy_crm_case], :group => group)

        add_associated_columns EasyCrmCaseQuery
      end

      def initialize_available_filters_with_easy_crm
        initialize_available_filters_without_easy_crm
        group = l('label_filter_group_easy_crm_case_item_query')

        add_principal_autocomplete_filter 'easy_crm_cases.assigned_to_id', { klass: User, order: 1, group: group, name: EasyCrmCase.human_attribute_name(:account_manager), includes: [:easy_crm_case] }
        if EasyUserType.easy_type_partner.any?
          add_principal_autocomplete_filter 'easy_crm_cases.external_assigned_to_id', { klass: User, order: 1, group: group, name: EasyCrmCase.human_attribute_name(:external_account_manager), includes: [:easy_crm_case] }
        end
        add_available_filter 'is_easy_crm_case_associated', {:type => :boolean, :order => 2,
                                                               :group => group, :name => l(:label_easy_crm_case_is_associated_to_easy_invoice)}

        add_available_filter 'easy_crm_cases_contacts_type', {type: :list,
                                                              order: 3,
                                                              values: Proc.new{ EasyContactType.all.collect { |t| [t.to_s, t.id.to_s] } },
                                                              group: group,
                                                              name: EasyContact.human_attribute_name(:easy_contact_type),
                                                              includes: [:easy_crm_case]}
      end

      def columns_with_me_with_easy_crm
        columns_with_me_without_easy_crm + ['easy_crm_cases.assigned_to_id', 'easy_crm_cases.external_assigned_to_id']
      end

    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceQuery', 'EasyCrm::EasyInvoiceQueryPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_invoicing) }
