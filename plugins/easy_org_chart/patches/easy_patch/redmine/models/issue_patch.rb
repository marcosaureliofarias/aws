module EasyOrgChart
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :visible?, :easy_org_chart

        class << self
          alias_method_chain :visible_condition, :easy_org_chart
        end

      end
    end

    module InstanceMethods

      def visible_with_easy_org_chart?(user = nil)
        user ||= User.current
        return true if visible_without_easy_org_chart?(user)
        perm = EasySetting.value(:easy_org_chart_share_subordinates_access)&.to_sym

        if [:direct_subordinates, :subordinates_tree].include?(perm)
          subordinate_user_ids = EasyOrgChart::Tree.children_for(user.id, perm == :direct_subordinates)
          User.where(id: subordinate_user_ids).any? {|subordinate| visible_without_easy_org_chart?(subordinate) }
        else
          false
        end
      end

    end

    module ClassMethods

      def visible_condition_with_easy_org_chart(user, options = {})
        unless user.admin?
          opts = options.dup
          perm = EasySetting.value(:easy_org_chart_share_subordinates_access)&.to_sym

          if [:direct_subordinates, :subordinates_tree].include?(perm)
            subordinate_user_ids = EasyOrgChart::Tree.children_for(user.id, perm == :direct_subordinates)
            if subordinate_user_ids.any?
              issues = Issue.arel_table
              sql = (issues[:author_id].in(subordinate_user_ids)).or(issues[:assigned_to_id].in(subordinate_user_ids)).to_sql
              opts[:additional_statement] = sql
            end
          end
          return visible_condition_without_easy_org_chart(user, opts)
        end
        visible_condition_without_easy_org_chart(user, options)
      end
    end

  end

end

RedmineExtensions::PatchManager.register_model_patch 'Issue', 'EasyOrgChart::IssuePatch'
