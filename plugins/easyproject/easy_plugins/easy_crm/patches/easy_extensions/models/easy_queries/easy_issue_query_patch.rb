module EasyCrm
  module EasyIssueQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_columns, :easy_crm

      end
    end

    module InstanceMethods

      def initialize_available_columns_with_easy_crm
        initialize_available_columns_without_easy_crm

        group = l(:label_easy_crm)
        @available_columns << EasyQueryColumn.new(:easy_crm_cases, caption: :heading_easy_crm_related_case_plural, preload: :easy_crm_cases, group: group)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyCrm::EasyIssueQueryPatch'

