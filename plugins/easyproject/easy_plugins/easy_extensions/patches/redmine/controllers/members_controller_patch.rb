module EasyPatch
  module MembersControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_action :edit_project_activity_roles, :only => [:edit]
        before_action :create_project_activity_roles, :only => [:new, :edit]
        after_action :delete_project_activity_roles, :only => [:destroy]

        alias_method_chain :create, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        private

        def edit_project_activity_roles
          if params[:member] && request.post?
            # current roles -  ids from form => if user remove role this role is destroy from par here only if role have only 1 member.
            (@member.role_ids - params[:member][:role_ids].collect(&:to_i)).each do |role_id_to_delete|
              if Role.find(role_id_to_delete).members.where(:project_id => @project.id).count == 1
                ProjectActivityRole.where(:project_id => @project.id, :role_id => role_id_to_delete).delete_all
              end
            end
          end
        end

        def create_project_activity_roles
          if params[:member] && request.post?
            role_ids = @project.all_members_roles.collect { |i| i.id.to_s }
            (params[:member][:role_ids] - role_ids).each do |role_id|
              @project.activities.each do |activity|
                ProjectActivityRole.create(:project_id => @project.id, :activity_id => activity.id, :role_id => role_id) if ProjectActivityRole.where(:project_id => @project.id, :activity_id => activity.id, :role_id => role_id).empty?
              end
            end if params[:member][:role_ids].present?
          end
        end

        def delete_project_activity_roles
          # actual project roles
          pmr = @project.all_members_roles.reorder(nil).pluck(:id).uniq
          par = @project.project_activity_roles.pluck(:role_id).uniq
          (par - pmr).each do |role_id|
            ProjectActivityRole.where(:project_id => @project.id, :role_id => role_id).delete_all
          end
        end

      end

    end

    module InstanceMethods

      def create_with_easy_extensions
        members = []
        if params[:membership]
          user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids]).map(&:to_i)
          user_ids << nil if user_ids.empty?
          inherited = Group.joins(:users).where(id: user_ids).distinct.pluck(:user_id)
          user_ids.each do |user_id|
            next if inherited.include?(user_id)
            member   = Member.new(project: @project, user_id: user_id)
            role_ids = params[:membership][:role_ids] || EasyUserType.joins(:users).where(users: { id: user_id }).pluck('easy_user_types.role_id').presence
            member.set_editable_role_ids(role_ids)
            members << member
          end

          @errors = []
          members.each do |member|
            @errors.concat(member.errors.full_messages) unless member.validate
          end
          @errors.uniq!
          @errors = @errors.join(', ')

          @project.members << members if @errors.blank?
        end

        respond_to do |format|
          format.html { redirect_to_settings_in_projects }
          format.js {
            @members = members
            @member  = Member.new
          }
          format.api {
            @member = members.first
            if @member.valid?
              render action: 'show', status: :created, location: membership_url(@member)
            else
              render_validation_errors(@member)
            end
          }
        end
      end

      def destroy_with_easy_extensions
        unless @member.deletable?
          respond_to_destroy_member and return
        end
        assigned_tasks = @member.assigned_tasks_for_reassign
        if assigned_tasks.exists?
          case params.dig(:after_destroy, :action).presence&.to_sym
          when :unassign
            new_assigned_to_id = nil
          when :assign
            new_assigned_to_id = params.dig(:after_destroy, :assigned_to_id)
          when nil
            respond_to_destroy_member_settings and return
          else
            render_error status: 422
            return
          end
          @member.transaction do
            assigned_tasks.update_all(assigned_to_id: new_assigned_to_id)
            @member.destroy
            raise ActiveRecord::Rollback unless @member.destroyed?
          end
          respond_to_destroy_member
        else
          @member.destroy
          respond_to_destroy_member
        end
      end

      private
       
        def respond_to_destroy_member
          respond_to do |format|
            format.html { redirect_to_settings_in_projects }
            format.js {
              unless @member.destroyed?
                render_error status: 422, message: l(:error_member_is_not_deletable)
              end
            }
            format.api {
              if @member.destroyed?
                render_api_ok
              else
                render_api_head :unprocessable_entity
              end
            }
          end
          return true
        end

        def respond_to_destroy_member_settings
          respond_to do |format|
            format.html { render partial: 'members/form_destroy_notice' }
            format.js { render partial: 'members/form_destroy_notice' }
            format.api {
              render_api_errors Array.wrap(l(:notice_api_destroy_member_assigned_to_tasks))
            }
          end
          return true
        end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'MembersController', 'EasyPatch::MembersControllerPatch'
