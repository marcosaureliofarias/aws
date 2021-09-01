module EasyCrm
  module JournalPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        acts_as_activity_provider :type => 'easy_crm_cases',
                                  :permission => :view_easy_crms,
                                  :author_key => :user_id,
                                  :scope => joins("JOIN #{EasyCrmCase.table_name} ON journalized_id = #{EasyCrmCase.table_name}.id").
                                            joins("JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyCrmCase.table_name}.project_id").
                                            joins("LEFT OUTER JOIN #{JournalDetail.table_name} ON #{JournalDetail.table_name}.journal_id = #{Journal.table_name}.id").
                                            where("#{Journal.table_name}.journalized_type = 'EasyCrmCase' AND" +
                                                  " (#{JournalDetail.table_name}.prop_key = 'status_id' OR #{Journal.table_name}.notes <> '')").distinct
        alias_method_chain :editable_by?, :easy_crm

      end
    end

    module InstanceMethods

      def editable_by_with_easy_crm?(user)
        if journalized.is_a?(EasyCrmCase)
          user && user.logged? && (user.allowed_to?(:edit_crm_case_notes, project) || (self.user == user && user.allowed_to?(:edit_own_crm_case_notes, project)))
        else
          editable_by_without_easy_crm?(user)
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Journal', 'EasyCrm::JournalPatch'
