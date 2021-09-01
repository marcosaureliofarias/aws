module EasyCrm
  module WorkflowsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :field_required?, :easy_crm

        def easy_crm_field_permission_tag(permissions, status, field, roles = nil)
          status_id = status.id.to_i
          name = field.is_a?(CustomField) ? field.id.to_s : field
          hidden = field.is_a?(CustomField) && !field.visible?
          options = [["", ""], [l(:label_readonly), "readonly"]]
          options << [l(:label_required), "required"] unless field_required?(field)
          html_options = {}

          if permissions[status_id].present? && perm = permissions[status_id][name]
            if perm.uniq.size > 1
              options << [l(:label_no_change_option), "no_change"]
              selected = 'no_change'
            else
              selected = perm.first
            end
          end

          if hidden
            options[0][0] = l(:label_hidden)
            selected = ''
            html_options[:disabled] = true
          end

          select_tag("permissions[#{status_id}][#{name}]", options_for_select(options, selected), html_options)
        end
      end
    end

    module InstanceMethods

      def field_required_with_easy_crm?(field)
        field.is_a?(CustomField) ? field.is_required? : WorkflowCrmPermission::REQUIRED_FIELDS.include?(field)
      end

    end
  end

end
EasyExtensions::PatchManager.register_helper_patch 'WorkflowsHelper', 'EasyCrm::WorkflowsHelperPatch'
