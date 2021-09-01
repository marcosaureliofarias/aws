module EasyPatch
  module ProjectsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        menu_item :projects, :only => [:index, :new, :create]
        accept_api_auth :index, :show, :create, :update, :destroy, :close, :reopen, :archive, :unarchive, :favorite

        default_search_scope :projects

        self.main_menu = false

        before_action :render_403, only: [:new, :create, :unarchive, :bulk_unarchive], if: -> { !EasyLicenseManager.has_license_limit?(:active_project_limit) }
        before_action :find_projects, only: [:bulk_destroy, :bulk_archive, :bulk_close, :bulk_reopen, :bulk_unarchive]
        before_action :find_project, except: [:index, :list, :new, :create, :toggle_custom_fields_on_project_form,
                                              :load_allowed_parents, :project_for_new_entity, :bulk_destroy,
                                              :bulk_archive, :bulk_close, :bulk_reopen, :bulk_unarchive, :bulk_modules]
        before_action :find_project_2, :only => [:load_allowed_parents]

        skip_before_action :require_admin, :only => [:archive, :copy, :destroy]
        before_action :authorize_bulk_unarchive, only: [:bulk_unarchive]
        before_action :authorize_global, only: [:bulk_destroy, :bulk_archive, :bulk_close, :bulk_reopen, :new, :create]
        before_action :authorize, :only => [:archive, :copy, :show, :close, :reopen, :personalize_show, :edit_custom_fields_form, :update_custom_fields_form, :destroy, :load_allowed_parents, :favorite, :easy_custom_menu_toggle]
        before_action :authorize_easy_project_template, :except => [:index, :show, :list, :new, :create, :toggle_custom_fields_on_project_form, :project_for_new_entity]
        before_action :change_personalize_show_rendering, :only => :personalize_show
        before_action :authorize_easy_project_editable, :only => [:edit, :settings, :update, :update_history]
        before_action :projects_perm_for_modules, only: [:bulk_modules]
        before_action :warning_scheduled_for_destroy, only: [:show, :edit, :settings]

        # cache_sweeper :my_page_my_projects_simple_sweeper, :projects_index_sweeper

        rescue_from EasyQuery::StatementInvalid, :with => :query_statement_invalid

        helper :easy_setting
        include EasySettingHelper

        alias_method_chain :archive, :easy_extensions
        alias_method_chain :close, :easy_extensions
        alias_method_chain :copy, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :reopen, :easy_extensions
        alias_method_chain :settings, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :unarchive, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        def authorize_archive
          authorize unless User.current.admin?
        end

        def authorize_bulk_unarchive
          unless User.current.admin?
            return render_403 :message => :notice_not_authorized_archived_project
          end
        end

        def favorite
          if User.current.favorite_projects.where(:id => @project.id).exists?
            User.current.favorite_projects.delete(@project)
            @favorited = false
          else
            User.current.favorite_projects << @project
            @favorited = true
          end

          respond_to do |format|
            format.js
            format.html { redirect_to project_path(@project) }
            format.api { render_api_ok }
          end
        end

        def personalize_show
        end

        def modules
          respond_to do |format|
            format.html {
              save_easy_settings(@project)

              if params[:project]
                @project.safe_attributes = params[:project]
                @project.save
              end
              @project.enabled_module_names = params[:enabled_module_names]
              flash[:notice]                = l(:notice_successful_update)

              if !params[:rendering_in_modal].present?
                redirect_back_or_default(settings_project_path(@project, :tab => 'modules'))
              else
                redirect_to settings_project_path(@project, :tab => 'modules')
              end
            }
            format.js
          end
        end

        def bulk_modules
          respond_to do |format|
            format.html {
              if params[:module_names]
                case params[:method]
                when 'enable_module'
                  @projects_with_perm.each do |project|
                    project.enabled_module_names = project.enabled_module_names | params[:module_names]
                 end
                when 'disable_module'
                  @projects_with_perm.each do |project|
                    project.enabled_module_names = project.enabled_module_names - params[:module_names]
                  end
                when 'overwrite'
                  @projects_with_perm.each do |project|
                    project.enabled_module_names = params[:module_names]
                 end
                end
                flash[:notice] = l(:notice_successful_update)
              end
              redirect_back_or_default projects_path
            }
            format.js
          end
        end

        def toggle_custom_fields_on_project_form
          params[:project][:project_custom_field_ids] = params[:project_custom_field_ids] if params[:project_custom_field_ids]

          @project                                    = Project.includes(:custom_values).find(params[:id]) if params[:id]
          @project                                    ||= Project.new
          @project.safe_attributes                    = params[:project]

          render :partial => 'form_project_custom_fields', :locals => { :custom_field_values => @project.visible_custom_field_values.sort_by { |i| i.custom_field.position }, :project => @project }
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def load_allowed_parents(user = User.current)
          options         = {}
          options[:force] = params[:force].to_sym unless params[:force].blank?

          terms      = params[:nested_autocomplete] ? params[:term].split(/, */) : [ params[:term] ]
          limit      = EasySetting.value(:easy_select_limit).to_i
          @self_only = params[:term].blank?
          @projects  = @project.match_projects_recursive(user, terms, limit, @self_only, options)

          respond_to do |format|
            format.api
          end
        end

        def edit_custom_fields_form
          respond_to do |format|
            format.js { render :partial => 'projects/edit_custom_fields_form', :locals => { :project => @project } }
          end
        end

        def update_custom_fields_form
          init_project_journal(@project)
          @project.safe_attributes = params[:project]

          if @project.save
            respond_to do |format|
              format.js { render partial: 'projects/update_custom_fields_form', locals: { project: @project, journals_limit: params[:journals_limit] } }
              format.api { render_api_ok }
            end
          else
            respond_to do |format|
              format.js { render :partial => 'projects/edit_custom_fields_form', :locals => { :project => @project } }
              format.api { render_validation_errors(@project) }
            end
          end
        end

        def update_history
          init_project_journal(@project)
          @project.save

          respond_to do |format|
            format.html { redirect_to settings_project_path(@project, :tab => 'history') }
          end
        end

        def project_for_new_entity
          @project      = Project.find(params[:project_id]) if params[:project_id].present?
          @entity_label = params[:label]
          if (@type = params[:type].try(:underscore)).present?
            respond_to do |format|
              format.js
              format.html do
                if @project.present?
                  redirect_to url_for(:controller => @type, :action => 'new', :project_id => @project.id)
                else
                  render_404
                end
              end
            end
          else
            render_404
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def easy_custom_menu_toggle
          @project.safe_attributes = params[:project]

          if @project.easy_has_custom_menu?
            User.current.as_admin do
              Redmine::MenuManager.allowed_items(:project_menu, User.current, @project).reverse_each do |item|
                if !@project.easy_custom_project_menus.where(:menu_item => item.name).exists?
                  @project.easy_custom_project_menus.create(:menu_item => item.name, :name => item.caption, :url => '')
                end
              end
            end
          else
            @project.easy_custom_project_menus.originals.destroy_all
          end

          respond_to do |format|
            format.js { render :template => 'easy_custom_project_menus/reload_index' }
          end
        end

        def bulk_destroy
          return unless @projects.size == 1

          render action: :destroy, params: @project_to_destroy = @projects.first
        end

        def bulk_archive
          errors = []
          @projects.each do |project|
            next if project.archived?

            init_project_journal(project)
            unless project.archive && project.current_journal&.save
              errors << "#{project.name} - #{l(:error_can_not_archive_project)}"
            end
          end
          flash[:error] = errors.join('<br>') if errors.any?
          redirect_back_or_default(projects_path)
        end

        def bulk_close
          @projects.each do |project|
            next unless project.active?

            init_project_journal(project)
            project.close
            project.current_journal&.save
          end
          respond_to do |format|
            format.html { redirect_back_or_default(projects_path) }
            format.js
          end
        end

        def bulk_reopen
          @projects.each do |project|
            next unless project.status == Project::STATUS_CLOSED

            init_project_journal(project)
            project.reopen
            project.current_journal&.save
          end
          respond_to do |format|
            format.html { redirect_back_or_default(projects_path) }
            format.js
          end
        end

        def bulk_unarchive
          @projects.each do |project|
            next if project.active?

            init_project_journal(project)
            project.unarchive
            project.current_journal&.save
          end
          redirect_back_or_default(projects_path)
        end

        def show_more_members
          @project_members = @project.members.visible.preload(:roles, { user: (Setting.gravatar_enabled? ? :email_address : :easy_avatar) }).sorted_by_importance
          if params[:q].present?
            user_ids         = User.like(params[:q])
            @project_members = @project_members.where(user_id: user_ids)
          end
          @principal_count = @project_members.count
          @principal_pages = Redmine::Pagination::Paginator.new @principal_count, per_page_option, params['page']
          @project_members = @project_members.offset(@principal_pages.offset).limit(@principal_pages.per_page).to_a

          respond_to do |format|
            format.js
          end
        end

        private

        def find_projects
          @projects = Project.where(:id => params[:data][:ids]) if params[:data]
          if @projects.blank?
            return render_404
          end
        end

        def init_project_journal(project)
          project.init_journal(User.current, params[:notes])
          # updates project's update_on
          current_time        = project.class.default_timezone == :utc ? Time.now.utc : Time.now
          project.updated_on = current_time
        end

        def change_show_rendering
          render_action_as_easy_page(EasyPage.find_by(page_name: 'project-overview'), nil, @project.id, project_path(@project, t: params[:t], jump: 'overview'), false, { project: @project, page_editable: User.current.allowed_to?(:manage_page_project_overview, @project) })
        end

        def change_personalize_show_rendering
          render_action_as_easy_page(EasyPage.find_by(page_name: 'project-overview'), nil, @project.id, project_path(@project, t: params[:t], jump: 'overview'), true, { project: @project })
        end

        def projects_perm_for_modules
          @projects_with_perm, @projects_without_perm = [], []
          scope = Project.visible.where(id: params[:ids])
          if User.current.admin?
            @projects_with_perm = scope
          else
            @projects_with_perm = scope.where(Project.allowed_to_condition(User.current, :select_project_modules))
            @projects_without_perm = scope.where.not(id: @projects_with_perm)
          end
        end

        # Rescues an invalid query statement. Just in case...
        def query_statement_invalid(exception)
          session.delete('easy_project_query')
          super
        end

        def authorize_easy_project_template
          if @project && !@project.new_record? && @project.easy_is_easy_template? && !User.current.allowed_to?(:edit_project_template, @project)
            deny_access
          end
        end

        def find_project_2
          @project                  = Project.find(params[:id]) if params[:id]
          @project                  ||= Project.new(:is_public => true) # must be public, load_allowed_parents needs: public or member
          @project.is_from_template = true if params[:from_template].to_s.to_boolean
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def authorize_easy_project_editable
          if @project.editable?
            true
          else
            deny_access
          end
        end

        def admin_projects_path(params = {})
          if request.delete?
            if User.current.admin?
              super(params)
            else
              projects_path(params)
            end
          else
            super(params)
          end
        end

      end
    end

    module InstanceMethods

      def show_with_easy_extensions
        if params[:jump] == 'overview' || api_request?
        elsif params[:jump] && redirect_to_project_menu_item(@project, params[:jump])
          # try to redirect to the requested menu item
          return
        elsif @project.default_project_page.present? &&
            @project.default_project_page != 'overview' &&
            redirect_to_project_menu_item(@project, @project.default_project_page)
          return
        end
        change_show_rendering unless api_request?
      end

      def index_with_easy_extensions
        retrieve_query(EasyProjectQuery)
        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        if @query.valid?
          respond_to do |format|
            format.html {
              if @query.display_as_tree?
                if !params[:root_id]
                  if @query.only_favorited?
                    @projects = @query.entities(:order => sort_clause)
                    add_non_filtered_projects
                    @only_favorited = true
                  else
                    find_projects_for_root(nil)
                  end
                else
                  return render_404 unless find_root
                  find_projects_for_root(@root.id)
                end

                @entities = @projects
                if params[:root_id] && request.xhr?
                  render template: 'projects/_projects_query_tree', layout: false, locals: { query: @query, projects: @projects }
                else
                  render :layout => !request.xhr?
                end
              else
                @projects = prepare_easy_query_render

                render_easy_query_html
              end
            }
            format.api {
              @offset, @limit = api_offset_and_limit
              @project_count  = @query.entity_count
              @projects       = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
            }
            format.csv {
              @projects = @query.prepare_export_result(order: sort_clause, offset: @offset, limit: @limit)
              send_data(projects_to_csv(@projects, @query), type: 'text/csv; header=present', filename: get_export_filename(:csv, @query))
            }
            format.pdf {
              @entities, _ = @query.prepare_export_result(:order => sort_clause, :offset => @offset, :limit => @limit)
              render_easy_query_pdf
            }
            format.xlsx {
              @entities, _ = @query.prepare_export_result(:order => sort_clause, :offset => @offset, :limit => @limit)
              render_easy_query_xlsx
            }
            format.atom {
              @projects = @query.entities(:order => 'created_on DESC', :limit => Setting.feeds_limit.to_i)
              render_feed(@projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
            }

          end
        else
          @projects = Project.visible.order('lft')
        end
      end

      def new_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:position, :name).to_a
        new_without_easy_extensions
        call_hook(:controller_projects_new, { :params => params, :project => @project })
      end

      def create_with_easy_extensions
        @project_custom_fields   = ProjectCustomField.order(:name).to_a
        @issue_custom_fields     = IssueCustomField.sorted.to_a
        @trackers                = Tracker.sorted.to_a
        @project                 = Project.new
        @project.inherit_members = !!EasySetting.value('default_project_inherit_members')
        @project.safe_attributes = params[:project]
        call_hook(:controller_projects_create_before_save, { :params => params, :project => @project })
        if @project.save
          save_easy_settings(@project)
          @project.add_default_member(User.current)
          call_hook(:controller_projects_create_after_save, { :params => params, :project => @project })
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_create)
              if params[:continue]
                attrs = { :parent_id => @project.parent_id }.reject { |k, v| v.nil? }
                redirect_to new_project_path(attrs)
              else
                redirect_to settings_project_path(@project)
              end
            }
            format.api { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
          end
        else
          respond_to do |format|
            format.html { render :action => 'new' }
            format.api { render_validation_errors(@project) }
          end
        end
      end

      def edit_with_easy_extensions
        @journals = @project.journals.preload([{ :user => :easy_avatar }, :details]).reorder("#{Journal.table_name}.id ASC").to_a
        @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @project)
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
        edit_without_easy_extensions
      end

      def update_with_easy_extensions
        init_project_journal(@project)

        save_easy_settings(@project)
        @project.safe_attributes = params[:project]
        if @project.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_back_or_default settings_project_path(@project, params[:tab])
            }
            format.api  { render_api_ok }
          end
        else
          respond_to do |format|
            format.html {
              settings
              render action: 'settings'
            }
            format.api  { render_validation_errors(@project) }
          end
        end
      end

      def settings_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:position, :name).all
        unless request.get?
          save_easy_settings(@project)
          flash[:notice] = l(:notice_successful_update) unless @project.errors.any?
        end
        if (ver_tab = project_settings_tabs.detect { |t| t[:name] == 'versions' }) && (params[:tab] == 'versions' || (params[:tab].blank? && project_settings_tabs.first == ver_tab))
          retrieve_query(EasyVersionQuery)
          sort_clear # custom sorting is disabled #231110 reset session store
          sort_init(@query.sort_criteria.presence || @query.default_sort_criteria.presence || ['effective_date', 'asc'])
          sort_update(@query.sortable_columns)
          @versions = prepare_easy_query_render
          render_easy_query(:action => 'settings')
        elsif params[:tab] == 'history'
          @journals = @project.journals.preload(:user, :details).reorder("#{Journal.table_name}.id ASC").to_a
          @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @project)
          @journals.reverse! if User.current.wants_comments_in_reverse_order?
        end
        settings_without_easy_extensions
      end

      def copy_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:name).to_a
        @issue_custom_fields   = IssueCustomField.sorted.to_a
        @trackers              = Tracker.sorted.all
        @root_projects         = Project.where(['parent_id IS NULL AND status = ?', Project::STATUS_ACTIVE]).order('name')
        @source_project        = Project.find(params[:id])
        begin
          @issue_trackers_count = Issue.where(:project_id => @source_project.id).group(:tracker).count
          @issues_by_tracker    = {}
          @issue_trackers_count.each_key do |tracker|
            @issues_by_tracker[tracker] = Issue.where(:project_id => @source_project.id, :tracker_id => tracker.id).select(:id)
          end
        rescue
        end
        if request.get?
          @project                 = Project.copy_from(@source_project)
          @project_identifier      = Setting.sequential_project_identifiers? ? Project.next_identifier : @project.identifier
          @subprojects             = @source_project.descendants.to_a
          @project.inherit_members = !!EasySetting.value('default_project_inherit_members')
          if @project
            @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
            @project.send(:assign_attributes, params[:project]) if params[:project]
          else
            redirect_to admin_projects_path
          end
        else
          if params[:project][:parent_id].blank?
            params[:project] = params[:project].except(:inherit_easy_invoicing_settings, :inherit_time_entry_activities, :inherit_easy_money_settings)
          end
          project_param        = params[:project]
          project_param        = project_param.to_unsafe_hash if project_param
          errs, saved_projects = [], []
          Mailer.with_deliveries(params[:notifications] == '1') do
            with_suprojects = params[:only] && params[:only].delete('subprojects')

            if with_suprojects
              project_param['id'] = @source_project.id.to_s

              projects_attributes = params.to_unsafe_hash[:subprojects] if params[:subprojects]
              projects_attributes ||= @source_project.descendants.non_templates.sorted.collect { |child| { 'name' => child.name, 'id' => child.id.to_s, 'identifier' => child.identifier } }
              projects_attributes << project_param

              @project, saved_projects, unsaved_projects = @source_project.project_with_subprojects_from_template(project_param['parent_id'], projects_attributes, { :only => params[:only], :copying_action => :copying_project })
              if unsaved_projects.any?
                unsaved_projects.each do |unsaved_project|
                  errs << l(:notice_failed_create_project_from_template, :errors => unsaved_project.nil? ? '' : unsaved_project.errors.full_messages.join('<br>'))
                end
              end
            else
              @project = @source_project.project_from_template(project_param['parent_id'], project_param, { :only => params[:only], :copying_action => :copying_project })
              if @project.nil? || !@project.valid?
                errs << l(:notice_failed_create_project_from_template, :errors => @project.nil? ? '' : @project.errors.full_messages.join('<br>'))
              else
                saved_projects << @project
              end
            end

            if errs.empty?
              copy_time_entry_settings(params[:project], saved_projects)
              call_hook(:controller_projects_copy_after_copy_successful, { :params => params, :source_project => @source_project, :saved_projects => saved_projects, :target_project => @project })
              flash[:notice] = l(:notice_successful_create_project_from_template)
              redirect_to settings_project_path(@project)
            else
              call_hook(:controller_projects_copy_after_copy_failed, { :params => params, :source_project => @source_project, :target_project => @project })
            end
          end
        end
      rescue ActiveRecord::RecordNotFound
        # source_project not found
        render_404
      end

      def archive_with_easy_extensions
        init_project_journal(@project)

        if @project.archive && @project.current_journal&.save
          respond_to do |format|
            format.html do
              flash[:notice] = l(:notice_project_successful_archive)
              if User.current.admin?
                redirect_to admin_projects_path(status: params[:status], name: params[:name])
              else
                redirect_to projects_path
              end
            end
            format.api { render_api_ok }
          end
        else
          error_message = "#{@project.name} - #{l(:error_can_not_archive_project)}"

          respond_to do |format|
            format.html do
              flash[:error] = error_message
              if User.current.admin?
                redirect_to admin_projects_path(status: params[:status], name: params[:name])
              else
                redirect_to projects_path
              end
            end
            format.api { render_api_errors(error_message) }
          end
        end
      end

      def unarchive_with_easy_extensions
        return if @project.active?
        init_project_journal(@project)

        if @project.unarchive && @project.current_journal&.save

          respond_to do |format|
            format.html do
              flash[:notice] = "#{@project.name} - #{l(:notice_project_successful_unarchive)}"
              redirect_to admin_projects_path(status: params[:status], name: params[:name])
            end
            format.api { render_api_ok }
          end
        else
          error_message = "#{@project.name} - #{l(:error_can_not_unarchive_project)}"

          respond_to do |format|
            format.html do
              flash[:error] = error_message
              redirect_to admin_projects_path(status: params[:status], name: params[:name])
            end
            format.api { render_api_errors(error_message) }
          end
        end
      end

      def close_with_easy_extensions
        init_project_journal(@project)

        @project.close && @project.current_journal&.save

        respond_to do |format|
          format.html { redirect_back_or_default project_path(@project) }
          format.api { render_api_ok }
        end
      end

      def reopen_with_easy_extensions
        init_project_journal(@project)

        @project.reopen && @project.current_journal&.save

        respond_to do |format|
          format.html { redirect_back_or_default project_path(@project) }
          format.api { render_api_ok }
        end
      end

      def destroy_with_easy_extensions
        @project_to_destroy = @project
        unless @project_to_destroy.can_delete_project_with_time_entries?
          flash.now[:error] = l(:error_could_not_delete_time_entries_on_the_project)
          return
        end

        if api_request? || (params[:confirm] && @project_to_destroy.name == params[:confirm_project_name])
          if @project_to_destroy.archive && @project_to_destroy.save
            @project_to_destroy.schedule_for_destroy!
            respond_to do |format|
              format.html {
                flash[:notice] = "#{@project_to_destroy.name} - #{l(:notice_project_scheduled_for_destroy)}"
                redirect_to admin_projects_path(status: params[:status], name: params[:name])
              }
              format.api { render_api_ok }
            end
          else
            error_message = "#{@project_to_destroy.name} - #{l(:error_can_not_delete_project_generic)}"
            respond_to do |format|
              format.html do
                flash[:error] = error_message if error_message
                redirect_to admin_projects_path(status: params[:status], name: params[:name])
              end
              format.api { render_api_errors(error_message) }
            end
          end
        elsif !api_request? && (params[:confirm] || params[:confirm_project_name])
          flash[:error] = l(:error_project_name_does_not_match)
        end

        # hide project in layout
        @project = nil
      end

      def find_projects_for_root(root_id = nil)
        unless root_id
          set_pagination(@query)
          @offset = @entity_pages.offset
        end

        @query.set_entity_scope_for_projects(params)
        @projects = @query.find_projects_for_root(root_id, order: sort_clause, limit: @limit, offset: @offset)
      end

      def find_root
        @root = Project.find(params[:root_id]) if params[:root_id]
      rescue ActiveRecord::RecordNotFound
      end

      def warning_scheduled_for_destroy
        if @project.scheduled_for_destroy? && !api_request?
          flash.now[:warning] = l(:warning_project_scheduled_for_destroy)
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ProjectsController', 'EasyPatch::ProjectsControllerPatch'
