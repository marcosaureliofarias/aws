module EasyResourceBase
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
          if Project.singleton_methods.include?(:update_project_entity_dates)
            alias_method_chain :update_project_entity_dates, :easy_resource_base
          end
        end
      end
    end

    module ClassMethods

      def update_project_entity_dates_with_easy_resource_base(entities, properties, date_delta)
        update_project_entity_dates_without_easy_resource_base(entities, properties, date_delta)

        if entities.first.is_a?(Issue) && properties.include?('start_date') && properties.include?('due_date')
          EasyResourceBase.reschedule_issues(entities, date_delta)
        end
      end

    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'Project', 'EasyResourceBase::ProjectPatch'
