module EasyPatch
  module PrincipalMembershipsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        before_action :find_principal, :only => [:new, :create, :autocomplete]
        skip_before_action :require_admin
        before_action :require_lesser_admin_for_membership

        alias_method_chain :new, :easy_extensions

        def require_lesser_admin_for_membership
          area = case
                 when params[:group_id].present?
                   :groups
                 when params[:user_id].present?
                   :users
                 end
          require_admin_or_lesser_admin(area)
        end
      end
    end

    module InstanceMethods

      def new_with_easy_extensions
        @projects = Project.active_and_planned.non_templates.reorder(:lft)
        @roles    = Role.find_all_givable
        respond_to do |format|
          format.html
          format.js
        end
      end

    end

  end
end

EasyExtensions::PatchManager.register_controller_patch 'PrincipalMembershipsController', 'EasyPatch::PrincipalMembershipsControllerPatch'
