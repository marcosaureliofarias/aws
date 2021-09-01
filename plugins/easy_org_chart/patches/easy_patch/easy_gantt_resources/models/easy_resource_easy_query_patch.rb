module EasyOrgChart
  module EasyResourceEasyQueryPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :available_filters, :easy_org_chart
        alias_method_chain :user_query, :easy_org_chart
      end
    end

    module InstanceMethods
      def available_filters_with_easy_org_chart
        available_filters_without_easy_org_chart

        unless @available_filters_with_easy_org_chart_added
          if User.current.logged? && supervisor_user_ids.include?(User.current.id)
            AddMySubordinatesToUsersFilter.call(@available_filters, 'user_id')
          end

          @available_filters_with_easy_org_chart_added = true
        end

        @available_filters
      end

      def user_query_with_easy_org_chart
        if filters['user_id']
          my_subordinate_user_ids = []
          if filters['user_id'][:values].delete('my_subordinates')
            my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id)
          elsif filters['user_id'][:values].delete('my_subordinates_tree')
            my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id, false)
          end
          if my_subordinate_user_ids.any?
            filters['user_id'][:values].concat my_subordinate_user_ids
          else
            filters['user_id'][:values].push 0
          end
        end

        user_query_without_easy_org_chart
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyResourceEasyQuery', 'EasyOrgChart::EasyResourceEasyQueryPatch', if: -> {Redmine::Plugin.installed? :easy_gantt_resources}
