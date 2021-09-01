module EasyQuickProjectPlanner
  module SettingsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :plugin, :easy_quick_planner
      end
    end

    module InstanceMethods
      def plugin_with_easy_quick_planner
        if request.post? && params[:id] == 'easy_quick_project_planner'
          project_settings = EasySetting.where(name: :quick_planner_fields).where(EasySetting.arel_table[:project_id].not_eq(nil))

          if params[:commit_action] == 'apply_all'
            project_settings.destroy_all
          else
            old_setting_value = EasySetting.value(:quick_planner_fields)
            new_setting_value = params[:easy_setting][:quick_planner_fields].delete_if{|v| v.blank? } if params[:easy_setting].present? && params[:easy_setting][:quick_planner_fields].is_a?(Array)

            EasySetting.transaction do
              Project.where("NOT EXISTS (#{project_settings.where(EasySetting.arel_table[:project_id].eq(Project.arel_table[:id])).to_sql})").find_each(:batch_size => 50) do |p|
                EasySetting.create(name: :quick_planner_fields, value: old_setting_value, project: p)
              end
              project_settings.where(value: new_setting_value.to_yaml).destroy_all
            end unless new_setting_value == old_setting_value
          end
        end
        plugin_without_easy_quick_planner
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'SettingsController', 'EasyQuickProjectPlanner::SettingsControllerPatch'
