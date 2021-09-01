module EasyAgileBoard
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods

      def sprints
        respond_to do |format|
          format.api {
            sprints = EasySprint.where(project_id: Project.visible).
                                 select('id', 'name AS value').
                                 like(params[:term]).
                                 limit(EasySetting.value('easy_select_limit').to_i)

            json_sprints = sprints.as_json
            json_sprints.prepend({ id: '', value: "--- #{l(:label_in_modules)} ---" }) if params[:include_system_options]&.include?('no_filter')
            render json: { easy_sprints: json_sprints }
          }
        end
      end

      def all_sprint_array
        issue = Issue.find_by(id: params[:issue_id])
        return if issue.nil?

        respond_to do |format|
          format.json do
            sprints = EasyAgileBoard.easy_sprints_for_select(issue.project)
            json = [["", ""]] + sprints.map { |o| { text: o[0], children: o[1].map { |i| { i[2].to_s => i[0].to_s } } } }
            render json: json
          end
        end
      end

      def projects_for_sprint
        @projects =  Project.has_module(:easy_scrum_board).non_templates.visible.allowed_to(:edit_easy_scrum_board).like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i)

        respond_to do |format|
          format.api { render template: 'easy_auto_completes/projects_with_id', formats: [:api] }
        end
      end

      def easy_scrum_board_visible_projects
        @projects = get_easy_scrum_board_visible_projects(params[:term], EasySetting.value('easy_select_limit').to_i)

        respond_to do |format|
          format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
        end
      end

      def get_easy_scrum_board_visible_projects(term = '', limit = nil)
        scope = easy_scrum_board_visible_projects_scope(term, limit)
        scope.to_a
      end

      def easy_scrum_board_visible_projects_scope(term='', limit=nil)
        if /^\d+$/.match?(term)
          scope = Project.active_and_planned.
            where(Project.allowed_to_condition(User.current, :view_easy_scrum_board)).where(id: term)
        else
          scope = Project.active_and_planned.
            where(Project.allowed_to_condition(User.current, :view_easy_scrum_board)).
            sorted.like(term).limit(limit)
        end
        scope
      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyAgileBoard::EasyAutoCompletesControllerPatch'
