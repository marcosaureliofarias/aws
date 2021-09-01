module EasyOrgChart
  module GlobalFiltersPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :find_entity, :easy_org_chart
        alias_method_chain :autocomplete_action_options, :easy_org_chart
      end
    end

    module InstanceMethods
      def autocomplete_action_options_with_easy_org_chart
        options = autocomplete_action_options_without_easy_org_chart
        options[:include_peoples] = "#{options[:include_peoples]}, subordinates"
        options
      end

      def find_entity_with_easy_org_chart(value)
        entity = find_entity_without_easy_org_chart(value)
        case value
        when 'my_subordinates'
          entity = EasyExtensions::GlobalFilters::Entity.new('my_subordinates', "<< #{I18n.t(:label_my_subordinates)} >>")
        when 'my_subordinates_tree'
          entity = EasyExtensions::GlobalFilters::Entity.new('my_subordinates_tree', "<< #{I18n.t(:label_my_subordinates_tree)} >>")
        end
        entity
      end
    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyExtensions::GlobalFilters::UserType', 'EasyOrgChart::GlobalFiltersPatch'
