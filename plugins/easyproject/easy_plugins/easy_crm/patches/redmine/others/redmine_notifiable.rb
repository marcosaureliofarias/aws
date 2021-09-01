module EasyCrm
  module RedmineNotifiablePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        class << self

          alias_method_chain :all, :easy_crm

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def all_with_easy_crm
        n = all_without_easy_crm
        n << Redmine::Notifiable.new('easy_crm_case_added')
        n << Redmine::Notifiable.new('easy_crm_case_updated')
        n
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Notifiable', 'EasyCrm::RedmineNotifiablePatch'
