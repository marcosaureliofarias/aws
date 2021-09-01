module EasyPatch
  module TimelogControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_action :find_time_entries, :only => [:bulk_edit, :bulk_update, :destroy, :change_issues_for_bulk_edit]
        before_action :find_entity
        skip_before_action :find_optional_issue, :only => [:new, :create] # find_optional_project
        before_action :find_optional_project, :only => [:new, :create, :index, :report]

        before_action :authorize_global, :only => [:new, :create, :index, :report, :user_spent_time, :change_role_activities, :change_projects_for_bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog, :resolve_easy_lock]
        before_action :authorize, :only => [:show, :edit, :update, :bulk_edit, :bulk_update, :destroy]
        before_action :check_easy_lock, :only => [:destroy]

        before_action :load_allowed_projects_for_bulk_edit #, :only => [:bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog, :new, :create, :edit]

        before_render :time_entries_clear_activities, :only => [:bulk_edit]
        before_render :load_allowed_issues_for_bulk_edit, :only => [:bulk_edit, :edit, :new, :create, :update]
        before_render :set_selected_visible_issue, :only => [:bulk_edit]

        helper :bulk_time_entries
        include BulkTimeEntriesHelper
        helper :easy_query
        include EasyQueryHelper
        helper :custom_fields
        include CustomFieldsHelper
        helper :sort
        include SortHelper
        helper :easy_attendances
        include EasyAttendancesHelper

        include EasyUtils::DateUtils

        alias_method_chain :bulk_update, :easy_extensions
        alias_method_chain :bulk_edit, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :find_optional_project, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :report, :easy_extensions
        alias_method_chain :time_entry_scope, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        def user_spent_time
          spent_on = []
          spent_on += params[:time_entries].collect { |k, v| v[:spent_on] } if !params[:time_entries].nil?
          spent_on += params[:saved_time_entries].collect { |k, v| v[:spent_on] } if !params[:saved_time_entries].nil?
          spent_on += [params[:spent_on]] if !params[:spent_on].nil?

          render(:partial => 'user_spent_time', :locals => { :spent_on => spent_on })
        end

        def change_role_activities
          @user    = User.find(params[:user_id]) unless params[:user_id].blank?
          @user    ||= User.current
          @project = Project.find(params[:project_id])

          new_project_id = params.delete('new_project_id')
          unless new_project_id.blank?
            begin
              @new_project = Project.find(new_project_id)
            rescue ActiveRecord::RecordNotFound
            end
            @time_entry.project = @new_project
          end

          @entity     = params[:entity_class].constantize.find(params[:entity_id]) unless params[:entity_class].blank? || params[:entity_id].blank?
          @activities = activity_collection(@user, params[:user_role_id])
          respond_to do |format|
            format.js # change_role_activities.js.erb
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def change_projects_for_bulk_edit
          @visible_projects = get_allowed_projects_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
          respond_to do |format|
            format.api
          end
        end

        def change_issues_for_bulk_edit
          respond_to do |format|
            format.api {
              @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
            }
            format.html {
              @visible_issues = get_allowed_issues_for_bulk_edit_scope
              render :partial => 'timelog/issues_for_bulk_edit', :locals => {}
            }
          end
        end

        def change_issues_for_timelog
          respond_to do |format|
            format.api {
              @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
            }
            format.html {
              @visible_issues = get_allowed_issues_for_bulk_edit_scope
              render :partial => 'timelog/issues_for_timelog', :locals => {}
            }
          end
        end

        def resolve_easy_lock
          @time_entries = TimeEntry.where(:id => params[:id].presence || params[:ids].presence)
          locked        = params[:locked].presence && params[:locked].to_boolean
          errors        = []
          @time_entries.find_each(:batch_size => 20) do |time_entry|
            time_entry.safe_attributes = { 'easy_locked' => locked }
            if !time_entry.save
              errors << "##{time_entry.id} - #{time_entry.errors.full_messages.join(', ')}"
            end
          end unless locked.nil?

          respond_to do |format|
            format.html do
              flash[:error] = errors.join('<br>'.html_safe) if !errors.empty?
              redirect_back_or_default(:action => 'index')
            end
          end
        end

        private

        def time_entries_clear_activities
          unless @projects.blank?
            @activities = [] if @projects.detect { |p| p.fixed_activity? }
          end
        end

        def load_allowed_projects_for_bulk_edit
          @visible_projects = get_allowed_projects_for_bulk_edit_scope

          if params[:time_entry] && params[:time_entry][:project_id].present?
            @selected_visible_project = Project.find_by(id: params[:time_entry][:project_id])
          elsif !@time_entry && params[:id]
            find_time_entry
          elsif !@project && params[:project_id]
            find_optional_project
          end

          @selected_visible_project ||= @project
          @selected_visible_project
        end

        def load_allowed_issues_for_bulk_edit
          @visible_issues = get_allowed_issues_for_bulk_edit_scope
        end

        def get_allowed_projects_for_bulk_edit_scope
          if User.current.admin?
            Project.active.non_templates.sorted.has_module(:time_tracking)
          else
            User.current.projects.non_templates.sorted.has_module(:time_tracking).by_permission(:log_time)
          end
        end

        def get_allowed_issues_for_bulk_edit_scope
          if @selected_visible_project
            scope = @selected_visible_project.issues.visible
            scope = scope.joins(:status).where(IssueStatus.table_name => { :is_closed => false }) unless EasyGlobalTimeEntrySetting.value('allow_log_time_to_closed_issue', User.current.roles_for_project(@selected_visible_project))
            scope
          else
            Issue.none
          end
        end

        def get_allowed_projects_for_bulk_edit(term = '', limit = nil)
          get_allowed_projects_for_bulk_edit_scope.where(["#{Project.table_name}.name like ?", "%#{term}%"]).limit(limit)
        end

        def get_allowed_issues_for_bulk_edit(term = '', limit = nil)
          if issues = get_allowed_issues_for_bulk_edit_scope
            issues.where(["#{Issue.table_name}.subject like ?", "%#{term}%"]).limit(limit)
          end
        end

        def set_selected_visible_issue
          @selected_visible_issue = { name: l(:label_no_change_option), id: '' }
          if params[:time_entry] && params[:time_entry][:issue_id].present? && params[:time_entry][:issue_id] != 'no_task'
            selected_issue          = (@visible_issues || Issue).find_by(id: params[:time_entry][:issue_id])
            @selected_visible_issue = { name: selected_issue.to_s, id: selected_issue.id } if selected_issue
          elsif params[:time_entry].present? && params[:time_entry][:issue_id] == 'no_task'
            @selected_visible_issue = { name: "(#{l(:label_no_task)})", id: 'no_task' }
          elsif @time_entries
            issues                  = @time_entries.collect { |t| t.issue if t.issue }.compact.uniq
            @selected_visible_issue = { name: issues.first.to_s, id: issues.first.id } if issues.size == 1
          end
        end

        def set_common_variables
          @only_me       = params[:only_me].nil? || params[:only_me] == 'false' ? false : true
          @query.only_me = @only_me

          if @issue && params[:with_descendants]
            @query.filters.delete('issue_id')
            @query.add_additional_statement("#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}")
          end

          @query.add_additional_statement("#{TimeEntry.table_name}.entity_id = #{@entity.id} AND #{TimeEntry.table_name}.entity_type = '#{TimeEntry.connection.quote_string(@entity.class.name)}'") if @entity

          if (@only_me == true) && User.current.allowed_to_globally_view_all_time_entries?
            @query.add_additional_statement("#{TimeEntry.table_name}.user_id = #{User.current.id}")
          end
        end

        def find_entity
          return true if params[:entity_id].blank? || params[:entity_type].blank?

          entity_klass = params[:entity_type].safe_constantize
          @entity      = entity_klass.find(params[:entity_id]) if entity_klass
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def check_easy_lock
          if @time_entries.any?(&:easy_locked?)
            flash[:error] = l(:error_time_entry_is_locked, :scope => :easy_attendance)
            redirect_back_or_default(:action => 'index')
            false
          end
        end

      end
    end

    module InstanceMethods

      def new_with_easy_extensions
        respond_to do |format|
          format.html {
            redirect_to(:controller => 'bulk_time_entries', :action => 'index', :project_id => @project, :issue_id => @issue, :back_url => params[:back_url])
          }
          format.js {
            redirect_to(:controller => 'bulk_time_entries', :action => 'index', :project_id => @project, :issue_id => @issue, :back_url => params[:back_url], :modal => true)
          }
        end
      end

      def bulk_edit_with_easy_extensions
        @available_activities = @projects.map(&:activities).reduce(:&)
        @custom_fields        = TimeEntry.first.available_custom_fields.select { |field| field.format.bulk_edit_supported }
      end

      def bulk_update_with_easy_extensions
        attributes = parse_params_for_bulk_update(params[:time_entry])

        unsaved_time_entries = []
        saved_time_entries   = []

        @time_entries.each do |time_entry|
          time_entry.reload
          if attributes[:project_id].present?
            time_entry.project_id = attributes[:project_id]
          end
          if params[:time_entry] && params[:time_entry][:issue_id] == 'no_task'
            time_entry.issue_id = nil
          else
            time_entry.safe_attributes = attributes
          end
          call_hook(:controller_time_entries_bulk_edit_before_save, { :params => params, :time_entry => time_entry })
          if time_entry.save
            saved_time_entries << time_entry
          else
            unsaved_time_entries << time_entry
          end
        end

        if unsaved_time_entries.empty?
          flash[:notice] = l(:notice_successful_update) unless saved_time_entries.empty?
          redirect_back_or_default project_time_entries_path(@projects.first)
        else
          @saved_time_entries   = @time_entries
          @unsaved_time_entries = unsaved_time_entries

          @time_entries = TimeEntry.visible.where(:id => unsaved_time_entries.map(&:id)).
              preload(:project => :time_entry_activities).
              preload(:user).to_a

          time_entries_clear_activities
          load_allowed_issues_for_bulk_edit
          set_selected_visible_issue
          bulk_edit
          render :action => 'bulk_edit'
        end
      end

      def index_with_easy_extensions
        if params[:from] && params[:to]
          params[:spent_on]   = params[:from] + '|' + params[:to]
          params[:set_filter] = '1'
        end
        retrieve_query(EasyTimeEntryQuery, false, { :dont_use_project => @issue.present?, :use_session_store => true })
        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        set_common_variables

        prepare_easy_query_render

        if request.xhr? && !@entities
          render_404
          return false
        end

        @query.display_show_sum_row = false
        @query.show_sum_row         = true

        if (f = @query.filters['spent_on']) && f[:values].is_a?(Hash)
          range                   = get_date_range(f[:operator] == 'date_period_1' ? '1' : '2', f[:values][:period], f[:values][:from], f[:values][:to], f[:values][:period_days])
          @from                   = range[:from]
          @to                     = range[:to]

          @easy_attendance_report = EasyAttendanceReport.new(User.current, @from, @to) if EasyAttendance.enabled? && @only_me == true
        end

        respond_to do |format|
          format.html { render_easy_query_html }
          format.api
          format.csv { send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query)) }
          format.xlsx { render_easy_query_xlsx }
          format.pdf { render_easy_query_pdf }
          format.atom { render_feed(@entities, :title => l(:label_spent_time)) }
        end
      end

      def create_with_easy_extensions
        @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :spent_on => User.current.today)

        if params[:time_entry] && params[:time_entry][:user_id] && User.current.admin?
          @time_entry.user = User.find_by_id(params[:time_entry][:user_id])
        else
          @time_entry.user = User.current
        end

        @time_entry.safe_attributes = params[:time_entry]

        if @time_entry.project && !User.current.allowed_to?(:log_time, @time_entry.project)
          render_403
          return
        end

        call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

        if @time_entry.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_create)
              if params[:continue]
                options = {
                    :time_entry => {
                        :project_id  => params[:time_entry][:project_id],
                        :issue_id    => @time_entry.issue_id,
                        :spent_on    => @time_entry.spent_on,
                        :activity_id => @time_entry.activity_id
                    },
                    :back_url   => params[:back_url]
                }
                if params[:project_id] && @time_entry.project
                  redirect_to new_project_time_entry_path(@time_entry.project, options)
                elsif params[:issue_id] && @time_entry.issue
                  redirect_to new_issue_time_entry_path(@time_entry.issue, options)
                else
                  redirect_to new_time_entry_path(options)
                end
              else
                redirect_back_or_default project_time_entries_path(@time_entry.project)
              end
            }
            format.api { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
          end
        else
          respond_to do |format|
            format.html { render :action => 'new' }
            format.api { render_validation_errors(@time_entry) }
          end
        end
      end

      def report_with_easy_extensions
        retrieve_query(EasyTimeEntryQuery, false, { :use_session_store => true })
        @query.display_filter_group_by_on_index = false
        @query.display_filter_settings_on_index = false
        @query.display_outputs_select_on_index  = false
        @query.output                           = 'list'
        @query.group_by                         = nil
        @query.sort_criteria                    = []
        @query.export_formats.delete(:pdf)

        export_options = { url: { controller: :timelog, action: :report } }
        [:xlsx, :csv].each { |format| @query.export_formats[format].merge!(export_options) }

        set_common_variables

        scope = @query.create_entity_scope

        @report = Redmine::Helpers::TimeReport.new(@project, @issue, params[:criteria], params[:columns], scope)
        if @report.periods.blank?
          @query.export_formats.delete(:csv)
          @query.export_formats.delete(:xlsx)
          return render_error :status => 422, :message => I18n.t(:error_report_invalid_criteria, :scope => :easy_attendance) if ['csv', 'xlsx'].include?(request.format)
        end

        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          format.csv { send_data(report_to_csv(@report), :type => 'text/csv; header=present', :filename => "#{l(:label_report)}.csv") }
          format.xlsx { send_data(report_to_xlsx(@report, @query, { :caption => :label_report }), :filename => "#{l(:label_report)}.xlsx") }
        end
      end

      def find_optional_project_with_easy_extensions
        # find optional issue
        if params[:issue_id].present?
          @issue = Issue.find(params[:issue_id])
          @project = @issue.project
        else
          @project = Project.find(params[:project_id]) if params[:project_id].present?
        end

        if @project && !@project.module_enabled?(:time_tracking)
          return render_404
        end

        @project
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def time_entry_scope_with_easy_extensions
        scope = TimeEntry.visible(User.current, :archive => :true)
        if @issue
          scope = scope.on_issue(@issue)
        elsif @project
          scope = scope.on_project(@project, Setting.display_subprojects_issues?)
        end

        date_range = get_date_range(params[:period_type], params[:period], params[:from], params[:to], params[:period_days])
        @from, @to = date_range[:from], date_range[:to]

        if @from
          scope = scope.where(["#{TimeEntry.table_name}.spent_on >= ?", @from])
        end

        if @to
          scope = scope.where(["#{TimeEntry.table_name}.spent_on <= ?", @to])
        end

        @only_me = params[:only_me] == 'true'
        if @only_me
          scope = scope.where(["#{TimeEntry.table_name}.user_id = ?", User.current.id])
        end

        scope
      end

      def destroy_with_easy_extensions
        @any_with_attendance = false
        @destroyed           = TimeEntry.transaction do
          @time_entries.each do |t|
            if t.easy_attendance.present?
              @any_with_attendance = true
              next
            end
            unless t.destroy && t.destroyed?
              raise ActiveRecord::Rollback
            end
          end
        end

        respond_to do |format|
          format.html {
            if @destroyed
              if @any_with_attendance
                flash[:error] = l(:notice_unable_delete_time_entry_with_attendance)
              else
                flash[:notice] = l(:notice_successful_delete)
              end
            else
              flash[:error] = l(:notice_unable_delete_time_entry)
            end
            redirect_back_or_default project_time_entries_path(@projects.first), :referer => true
          }
          format.js
          format.api {
            if @destroyed
              if @any_with_attendance
                render_api_errors(l(:notice_unable_delete_time_entry_with_attendance))
              else
                render_api_ok
              end
            else
              render_api_errors(l(:notice_unable_delete_time_entry))
            end
          }
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'TimelogController', 'EasyPatch::TimelogControllerPatch'
