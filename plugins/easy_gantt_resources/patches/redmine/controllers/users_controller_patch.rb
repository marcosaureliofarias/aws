module EasyGanttResources
  module UsersControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :update, :easy_gantt_resources
      end
    end

    module InstanceMethods

      def update_with_easy_gantt_resources
        EasyGanttResources.user_easy_gantt_resource_attributes_from_params(@user, params[:user]) if @user && User.current.allowed_to_globally?(:manage_user_easy_gantt_resources)

        update_without_easy_gantt_resources
      end
    end

    module ClassMethods
    end

  end
end
RedmineExtensions::PatchManager.register_controller_patch 'UsersController', 'EasyGanttResources::UsersControllerPatch'
