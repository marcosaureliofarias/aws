module EasyOrgChart
  module UserPreparationPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :add_additional_select_options, :easy_org_chart
        alias_method_chain :need_to_reload_assignees?, :easy_org_chart

        delegate :subordinates_options, to: :class

        class << self
          alias_method_chain :user_options_with_name, :easy_org_chart
          alias_method_chain :add_principals_from_options, :easy_org_chart
        end
      end
    end

    module InstanceMethods
      def add_additional_select_options_with_easy_org_chart(options_container = [], selected_additional_options = [])
        values = []
        User.add_my_subordinates_options(values)
        values = values.index_by {|option| option.last }

        (selected_additional_options & user_options_with_name).each do |option|
          next unless values[option]
          options_container << { id: option, value: values[option].first }
        end
      end

      def need_to_reload_assignees_with_easy_org_chart?
        (selected_additional_options & user_options_with_name).any?
      end
    end

    module ClassMethods
      def user_options_with_name_with_easy_org_chart
        user_options_with_name_without_easy_org_chart.concat(subordinates_options)
      end

      def subordinates_options
        %w(my_subordinates my_subordinates_tree)
      end

      def add_principals_from_options_with_easy_org_chart(user_ids_container, options = [])
        if (options & subordinates_options).any?
          related = options.include?('my_subordinates')
          my_subordinate_user_ids = EasyOrgChart::Tree.children_for(User.current.id, related)
          user_ids_container.concat(my_subordinate_user_ids)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'EasyScheduler::UserPreparation', 'EasyOrgChart::UserPreparationPatch', if: -> { Redmine::Plugin.installed?(:easy_scheduler) }
