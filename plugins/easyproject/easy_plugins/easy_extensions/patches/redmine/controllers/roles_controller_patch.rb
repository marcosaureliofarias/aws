module EasyPatch
  module RolesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # cache_sweeper :role_or_permissions_changed_sweeper

        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        before_action :find_role, :only => [:show, :edit, :update, :destroy, :move_members]

        # Move old members and delete old role
        def move_members
          @other_roles = Role.givable.where("#{Role.table_name}.id <> ?", @role.id)

          if request.post? && params[:role_to_id].present?
            @new_role = Role.find(params[:role_to_id])

            @role.member_roles.each do |member_role|
              # Remove relations for inherited roles
              # If parent role will be removed before children -> they will be deleted
              MemberRole.where(inherited_from: member_role.id).update_all(inherited_from: nil)

              # Check if role already exist
              if MemberRole.exists?(member_id: member_role.member_id, role_id: @new_role.id)
                member_role.destroy
              else
                member_role.role_id = @new_role.id
                member_role.save
              end
            end

            @role.reload
            @role.destroy
            redirect_to roles_path
          end
        end

      end
    end

    module InstanceMethods

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:roles)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:roles)
      end

      def update_with_easy_extensions
        @role.safe_attributes = params[:role]
        if @role.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_to roles_path(:page => params[:page])
            }
            format.js { head 200 }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.js { head 422 }
            format.api { render_validation_errors(@role) }
          end
        end
      end

      def destroy_with_easy_extensions
        if @role.members.any? && !@role.builtin? && Role.givable.count >= 2
          flash[:error] = l(:error_can_not_remove_role)
          redirect_to role_move_members_path(@role)
        else
          begin
            @role.destroy
          rescue
            flash[:error] = l(:error_can_not_remove_role)
          ensure
            redirect_to roles_path
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'RolesController', 'EasyPatch::RolesControllerPatch'
