module EasyPatch
  module WorkflowsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # alias_method_chain :edit_membership, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions

      end
    end

    module InstanceMethods

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:workflows)
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'WorkflowsController', 'EasyPatch::WorkflowsControllerPatch'
