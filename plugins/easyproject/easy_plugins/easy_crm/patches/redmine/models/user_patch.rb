module EasyCrm
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_user_targets, dependent: :destroy

        alias_method_chain :notify_about?, :easy_crm
        alias_method_chain :remove_references_before_destroy, :easy_crm

      end
    end

    module InstanceMethods

      def notify_about_with_easy_crm?(object)
        n = notify_about_without_easy_crm?(object)
        return n unless n.nil?

        if object.is_a?(EasyCrmCase)
          case mail_notification
          when 'selected', 'only_my_events'
            object.author == self ||
              is_or_belongs_to?(object.assigned_to) ||
              is_or_belongs_to?(object.external_assigned_to) ||
              is_or_belongs_to?(object.previous_assignee) ||
              is_or_belongs_to?(object.previous_external_assignee) ||
              object.watched_by?(self)
          when 'only_assigned'
            is_or_belongs_to?(object.assigned_to) ||
              is_or_belongs_to?(object.external_assigned_to) ||
              is_or_belongs_to?(object.previous_assignee)
              is_or_belongs_to?(object.previous_external_assignee)
          when 'only_owner'
            object.author == self
          end
        end
      end

      def remove_references_before_destroy_with_easy_crm
        remove_references_before_destroy_without_easy_crm
        substitute = User.anonymous
        EasyCrmCase.where(author_id: self.id).update_all(author_id: substitute.id)
        EasyCrmCase.where(assigned_to_id: self.id).update_all(assigned_to_id: nil)
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyCrm::UserPatch'
