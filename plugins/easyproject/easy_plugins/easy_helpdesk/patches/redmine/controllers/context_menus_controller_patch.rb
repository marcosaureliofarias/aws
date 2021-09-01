module EasyHelpdesk
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_helpdesk_projects
          @easy_helpdesk_projects = EasyHelpdeskProject.where(:id => params[:ids]).preload(:project).to_a
          (render_404; return) unless @easy_helpdesk_projects.present?

          if (@easy_helpdesk_projects.size == 1)
            @easy_helpdesk_project = @easy_helpdesk_projects.first
          end

          @easy_helpdesk_project_ids = @easy_helpdesk_projects.map(&:id).sort

          @projects = @easy_helpdesk_projects.collect(&:project).compact.uniq
          @project = @projects.first if @projects.size == 1

          if @project
            @assignables = @project.assignable_users
            @trackers = @project.trackers
          else
            @assignables = @projects.map(&:assignable_users).reduce(:&)
            @trackers = @projects.map(&:trackers).reduce(:&)
          end

          @back_url = back_url

          render :layout => false
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyHelpdesk::ContextMenusControllerPatch'
