module EasyPatch
  module WorkflowPermissionPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
          alias_method_chain :rules_by_status_id, :easy_extensions

          def easy_rules_by_role_id(status_id, tracker_id, role_ids)
            RequestStore.store["#{self.name}_rules_by_status_id_s#{status_id}_t#{tracker_id}_r#{role_ids.join('-')}"] ||=
                WorkflowPermission.where(:tracker_id => tracker_id, :old_status_id => status_id, :role_id => role_ids).inject({}) do |h, wp|
                  h[wp.field_name]             ||= {}
                  h[wp.field_name][wp.role_id] = wp.rule
                  h
                end
          end
        end
      end
    end

    module ClassMethods
      def rules_by_status_id_with_easy_extensions(trackers, roles)
        RequestStore.store["#{self.name}_rules_by_status_id_t#{trackers.map(&:id).join('-')}_r#{roles.map(&:id).join('-')}"] ||= rules_by_status_id_without_easy_extensions(trackers, roles)
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'WorkflowPermission', 'EasyPatch::WorkflowPermissionPatch'
