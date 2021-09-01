module EasyOrgChart
  module EasyAttendancePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :approval_mail, :easy_org_chart
        alias_method_chain :can_approve?, :easy_org_chart

      end
    end

    module InstanceMethods

      def approval_mail_with_easy_org_chart
        email_addresses = Array(approval_mail_without_easy_org_chart)

        superior_user_id = EasyOrgChart::Tree.ancestor_for(user_id)
        if superior_user_id
          email_addresses << EmailAddress.where(user_id: superior_user_id, is_default: true).limit(1).pluck(:address).first
        end

        email_addresses
      end

      def can_approve_with_easy_org_chart?(user = nil)
        user ||= User.current

        can_approve_without_easy_org_chart?(user) || EasyOrgChart::Tree.ancestry_for(self.user_id).include?(user.id)
      end

    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyAttendance', 'EasyOrgChart::EasyAttendancePatch', if: -> {Redmine::Plugin.installed? :easy_attendances}
