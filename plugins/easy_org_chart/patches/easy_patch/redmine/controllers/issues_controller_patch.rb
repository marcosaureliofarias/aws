module EasyOrgChart
  module IssuesControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        skip_before_action :authorize, only: :show
        before_action :authorize_subordinate, only: :show

      end
    end

    module InstanceMethods
      def authorize_subordinate
        perm = EasySetting.value(:easy_org_chart_share_subordinates_access)&.to_sym
        if [:direct_subordinates, :subordinates_tree].include?(perm)
          subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id, perm == :direct_subordinates) & [@issue.author_id, @issue.assigned_to_id].compact
          if subordinate_user_ids.any?
            return true if User.where(id: subordinate_user_ids).any? {|subordinate| subordinate.allowed_to?({controller: controller_name, action: action_name}, @project) }
          end
        end

        authorize
      end

    end

    module ClassMethods

    end

  end

end

RedmineExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyOrgChart::IssuesControllerPatch'
