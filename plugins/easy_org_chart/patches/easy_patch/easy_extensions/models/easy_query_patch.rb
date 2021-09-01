module EasyOrgChart
  module EasyQueryPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :all_users_values, :easy_org_chart
        alias_method_chain :personalized_field_value_for_statement, :easy_org_chart
        alias_method_chain :sql_for_custom_field, :easy_org_chart
        alias_method_chain :integer_value_valid?, :easy_org_chart
      end
    end

    module InstanceMethods
      def all_users_values_with_easy_org_chart(options = {})
        values = all_users_values_without_easy_org_chart(options)

        if User.current.logged? && options[:include_me] && supervisor_user_ids.include?(User.current.id)
          ::AddMySubordinatesToUsersList.call(values)
        end

        values
      end

      def personalized_field_value_for_statement_with_easy_org_chart(field, value)
        value = personalized_field_value_for_statement_without_easy_org_chart(field, value)

        if self.columns_with_me.include?(field)
          if value.is_a?(Array) && (value & %w(my_subordinates my_subordinates_tree)).any?
            my_subordinate_user_ids = []

            if value.delete('my_subordinates')
              my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id)
            end

            if value.delete('my_subordinates_tree')
              my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id, false)
            end

            if my_subordinate_user_ids.any?
              value.concat my_subordinate_user_ids
            else
              value.push 0
            end
          elsif value == 'my_subordinates'
            value = EasyOrgChart::Tree.children_for(User.current.id).presence || [0]
          elsif value == 'my_subordinates_tree'
            value = EasyOrgChart::Tree.children_for(User.current.id, false).presence || [0]
          end
        end

        value
      end

      def supervisor_user_ids
        EasyOrgChart::Tree.supervisor_user_ids
      end

      def sql_for_custom_field_with_easy_org_chart(field, operator, value, custom_field_id)
        filter = self.available_filters[field]

        return unless filter

        if (filter[:field].format.name == 'easy_lookup') || (filter[:field].format.target_class && filter[:field].format.target_class <= User)
          if value.is_a?(Array)
            my_subordinate_user_ids = []
            if value.delete('my_subordinates')
              my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id)
            elsif value.delete('my_subordinates_tree')
              my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id, false)
            end
            if my_subordinate_user_ids.any?
              value += my_subordinate_user_ids
            else
              value.push('0')
            end
          end
        end

        sql_for_custom_field_without_easy_org_chart(field, operator, value, custom_field_id)
      end

      def integer_value_valid_with_easy_org_chart?(field, value)
        return true if @available_filters[field][:klass] && @available_filters[field][:klass] <= Principal && value.in?(['my_subordinates', 'my_subordinates_tree'])
        integer_value_valid_without_easy_org_chart? field, value
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyQuery', 'EasyOrgChart::EasyQueryPatch'
