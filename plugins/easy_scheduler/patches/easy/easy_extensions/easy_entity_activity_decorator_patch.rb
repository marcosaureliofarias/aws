module EasyScheduler
  module EasyEntityActivityDecoratorPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include InstanceMethods

      base.class_eval do
        alias_method_chain :types, :easy_scheduler
      end
    end

    module InstanceMethods
      def types_with_easy_scheduler
        types_without_easy_scheduler.merge({
          EasyCrmCase.to_s => l(:field_easy_crm_case),
          EasyContact.to_s => l(:field_easy_contact)
        })
      end

      def default_type
        entity_type || 'EasyCrmCase'
      end

      def contacts_attendees
        easy_entity_activity_contacts.map { |c| { value: c.name, id: c.id } }
      end
    end

    module ClassMethods
    end

  end
end

RedmineExtensions::PatchManager.register_other_patch 'EasyEntityActivityDecorator',
                                                     'EasyScheduler::EasyEntityActivityDecoratorPatch',
                                                     if: proc { Redmine::Plugin.installed?(:easy_crm) && Redmine::Plugin.installed?(:easy_contacts) }
