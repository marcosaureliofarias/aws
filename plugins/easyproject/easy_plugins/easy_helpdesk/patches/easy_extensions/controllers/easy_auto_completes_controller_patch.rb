module EasyHelpdesk
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_helpdesk_projects
          @projects = get_visible_easy_helpdesk_projects(params[:term], EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
          end
        end

        def easy_projects_with_easy_helpdesk
          @projects = Project.joins(:easy_helpdesk_project).sorted.like(params[:term]).limit(15)
          respond_to do |format|
            format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
          end
        end

        def easy_sla_event_issues
          term = params[:term]
          base = Issue.visible.joins(:project).where(get_project_if_exist)
          @entities = (/^\d+$/.match?(term)) ? Array(base.find_by(id: term)) : base.like(term).limit(EasySetting.value('easy_select_limit').to_i).to_a

          @name_column = :to_s
          respond_to do |format|
            format.api { render :template => 'easy_auto_completes/entities_with_id', :formats => [:api], locals: {additional_select_options: false} }
          end
        end

        private
        
        def get_visible_easy_helpdesk_projects(term='', limit=nil)
          scope = get_visible_projects_scope(term, limit)
          scope = scope.active.has_module(:issue_tracking)
          scope.all
        end
      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyHelpdesk::EasyAutoCompletesControllerPatch'
