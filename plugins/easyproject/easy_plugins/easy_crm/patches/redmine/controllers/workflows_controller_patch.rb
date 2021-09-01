module EasyCrm
  module WorkflowsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

      end
    end

    module InstanceMethods

      def crm_permissions
        if request.post? && params[:permissions].present?
          permissions = params[:permissions].deep_dup.each do |field, rule_by_status_id|
            rule_by_status_id.reject! {|status_id, rule| rule == 'no_change'}
          end
          WorkflowCrmPermission.replace_permissions(permissions)
          flash[:notice] = l(:notice_successful_update)
          redirect_to_referer_or workflows_crm_permissions_path
          return
        end
        @fields = WorkflowCrmPermission::AVAILABLE_FIELDS.map {|field| [field, easy_crm_field_name(field)]}
        @custom_fields = EasyCrmCaseCustomField.non_computed_fields.sorted
        @statuses = EasyCrmCaseStatus.sorted
        @permissions = WorkflowCrmPermission.rules_by_status_id
      end

      private

      def easy_crm_field_name(field)
        if field == 'assigned_to_id'
          field = 'account_manager'
        elsif field == 'external_assigned_to_id'
          field = 'external_account_manager'
        end
        l("activerecord.attributes.easy_crm_case." + field.sub(/_id$/, '').sub(/_ids$/, 's'))
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'WorkflowsController', 'EasyCrm::WorkflowsControllerPatch'
