module EasyCrm
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_crm_projects
          @projects = get_visible_easy_crm_projects(params[:term], EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
          end
        end

        def easy_crm_case_statuses
          render :json => EasyCrmCaseStatus.sorted.collect{|s| {:text => s.name, :value => s.id}}
        end

        def get_visible_crm_cases_for_invoice
          @entities = EasyCrmCase.where(:project => Project.has_module(:easy_invoicing).has_module(:easy_crm).visible.non_templates.allowed_to(:easy_invoicing_manage_easy_invoice)).like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i)

          @name_column = :name

          respond_to do |format|
            format.api {render :template => 'easy_auto_completes/entities_with_id'}
          end
        end

        def get_visible_easy_crm_cases
          @entities = EasyCrmCase.visible.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i)

          @name_column = :name

          respond_to do |format|
            format.api {render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: {additional_select_options: false}}
          end
        end

        # ckeditor
        # easy_crm_case#123
        def ckeditor_easy_crm_cases
          column = "#{EasyCrmCase.table_name}.id"
          column = "CAST(#{column} AS TEXT)" if Redmine::Database.postgresql?
          @entities = EasyCrmCase.visible.where(Redmine::Database.like(column, '?'), "#{params[:query]}%").
            limit(EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.json { render json: @entities.map{|e| {id: e.id, name: e.id, subject: e.name}} }
          end
        end

        def assignable_principals_easy_crm_case
          entity   = EasyCrmCase.find_by(id: params[:easy_crm_case_id])
          entity   ||= EasyCrmCase.new
          project  = entity.project
          project  ||= Project.find_by(id: params[:project_id]) if params[:project_id]
          projects = Project.where(id: params[:project_ids]).to_a if params[:project_ids]
          projects ||= [project]

          if projects.any?
            assignable_user_ids = EasyPrincipalQuery.get_assignable_principals(projects, params[:term], types: ['User']).pluck(:id)
            assignable_users = User.where(id: assignable_user_ids).sorted
          else
            assignable_users = User.active.non_system_flag.sorted
          end

          assignable_users = if params[:external]
            assignable_users.easy_type_partner
          else
            assignable_users.easy_type_regular
          end

          assignable_principals_base(entity, assignable_users.to_a)
        end

        private

        def get_visible_easy_crm_projects(term='', limit=nil)
          scope = get_visible_projects_scope(term, limit)
          scope = scope.active.has_module(:easy_crm)
          scope
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyCrm::EasyAutoCompletesControllerPatch'
