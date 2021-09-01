module RedmineTestCases
  module EasyIssueQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize_available_columns, :redmine_test_cases
        alias_method_chain :initialize_available_filters, :redmine_test_cases
      end
    end

    module InstanceMethods
      def initialize_available_filters_with_redmine_test_cases
        initialize_available_filters_without_redmine_test_cases

        on_filter_group(l(:label_test_cases)) do
          add_available_filter 'test_cases', { type:        :list_autocomplete,
                                               source:      'root_test_case',
                                               source_root: 'entities',
                                               name:        l(:label_filter_group_test_case_query)
                                             }
        end
      end

      def initialize_available_columns_with_redmine_test_cases
        initialize_available_columns_without_redmine_test_cases

        @available_columns << EasyQueryColumn.new(:test_cases, :preload => [:test_cases], :group => l("label_filter_group_test_case_query"))
      end

      def sql_for_test_cases_field(field, operator, value)
        op = operator.start_with?('!') ? 'NOT ' : ''
        arel = EasyEntityAssignment.arel_table
        conditions = arel[:entity_from_type].eq('Issue').and(arel[:entity_to_type].eq('TestCase'))
        conditions = conditions.and(arel[:entity_to_id].in(value)) unless operator.include?('*')
        sql = EasyEntityAssignment.where(conditions).to_sql
        "#{op}EXISTS (#{sql} AND #{arel.table_name}.entity_from_id = #{self.entity.table_name}.id)"
      end
    end

    module ClassMethods

    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'RedmineTestCases::EasyIssueQueryPatch', if: proc {Redmine::Plugin.installed? :easy_extensions}
