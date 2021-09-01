module EasyPatch
  module AdminControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        helper :projects, :easy_query
        include ProjectsHelper
        helper :sort
        include SortHelper
        include EasyQueryHelper
        include CustomFieldsHelper
        helper :custom_fields

        skip_before_action :require_admin, only: [:index]
        before_action :require_admin_or_lesser_admin, only: [:index]

        alias_method_chain :projects, :easy_extensions
        alias_method_chain :plugins, :easy_extensions

        def manage_plugins
          redirect_to admin_plugins_path
        end

        private

        def require_admin_or_lesser_admin
          return unless require_login

          if User.current.admin? || User.current.easy_lesser_admin?
            true
          else
            render_403
            false
          end
        end

        def find_root
          @root = Project.find(params[:root_id]) if params[:root_id]
        rescue ActiveRecord::RecordNotFound
        end

        def find_projects_for_root(root_id = nil)
          unless root_id
            set_pagination(@query)
            @offset = @entity_pages.offset
          end

          @projects = @query.find_projects_for_root(root_id, order: sort_clause, limit: @limit, offset: @offset)
        end

      end
    end

    module InstanceMethods

      def plugins_with_easy_extensions
        @plugins = Redmine::Plugin.all(:only_visible => true).sort_by { |p| p.name.is_a?(Symbol) ? l(p.name) : p.name }
      end

      def projects_with_easy_extensions
        retrieve_query(EasyAdminProjectQuery)
        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)
        call_hook(:controller_admin_projects, query: @query)

        if @query.valid?
          respond_to do |format|
            format.html {
              if @query.display_as_tree?
                if params[:root_id]
                  return render_404 unless find_root
                  find_projects_for_root(@root.id)
                else
                  find_projects_for_root(nil)
                end

                @entities = @projects
                if request.xhr?
                  if params[:root_id]
                    render template: 'admin/projects', layout: false, locals: { projects: @projects }
                  else
                    render action: 'projects', layout: false
                  end
                end
              else
                @projects = prepare_easy_query_render

                render_easy_query_html
              end
            }
            format.csv {
              @entities = @query.prepare_export_result(order: sort_clause, offset: @offset, limit: @limit)
              send_data(projects_to_csv(@entities, @query), type: 'text/csv; header=present', filename: get_export_filename(:csv, @query))
            }
            format.pdf {
              @entities, _ = @query.prepare_export_result(order: sort_clause, offset: @offset, limit: @limit)
              render_easy_query_pdf
            }
            format.xlsx {
              @entities, _ = @query.prepare_export_result(order: sort_clause, offset: @offset, limit: @limit)
              render_easy_query_xlsx
            }
            format.api do
              @offset, @limit = api_offset_and_limit
              @project_count  = @query.entity_count
              @projects       = @query.entities(order: sort_clause, offset: @offset, limit: @limit)
              render 'projects/index'
            end
          end
        else
          @projects = Project.visible.order('lft')
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'AdminController', 'EasyPatch::AdminControllerPatch'
