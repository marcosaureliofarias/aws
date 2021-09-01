module EasyPatch
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :projects
        helper :easy_rake_tasks

        before_render :time_entries_clear_activities, :only => :time_entries
        before_render :time_entries_add_issues, :only => :time_entries
        before_render :time_entries_disable_delete_with_easy_attendance, :only => :time_entries
        before_render :ensure_time_entry_permissions, :only => :time_entries

        after_action :ensure_context_menu_response

        alias_method_chain :issues, :easy_extensions
        alias_method_chain :time_entries, :easy_extensions

        def versioned_attachments
          if params[:ids].any?
            @attachments = Attachment.preload(:container).find(params[:ids])
            @attachment_ids = @attachments.map(&:id)
            return deny_access unless @attachments.all?(&:visible?)

            if @attachments.size == 1
              @attachment = @attachments.first
              @att_v = @attachment.versions.reverse
            end
            @can = {}
            @can[:destroy] = @attachments.all? {|attachment| attachment.deletable? }
          end
          render layout: false
        end

        def versions
          @project  = Project.find(params[:project_id]) if params[:project_id]
          @versions = Version.visible.where(:id => params[:ids])

          if @versions.size == 1
            @version = @versions.first
          end

          @can = {
              :edit    => User.current.allowed_to?(:manage_versions, @project, :global => true),
              :destroy => User.current.allowed_to?(:manage_versions, @project, :global => true)
          }
          render :layout => false
        end

        def easy_attendances
          @easy_attendances = EasyAttendance.preload([:user, :easy_attendance_activity]).where(:id => params[:ids])
          easy_attendance   = @easy_attendances.first if @easy_attendances.one?
          @activities       = EasyAttendanceActivity.sorted.user_activities
          @activities       = @activities.where(at_work: easy_attendance.activity.at_work) if easy_attendance
          @users            = @easy_attendances.collect(&:user).uniq
          @user             = @users.first if @users.count == 1
          edit_permitted    = @easy_attendances.all?(&:can_edit?)
          bulk_permissions  = { :approve => true, :request_cancel => true, :destroy => true }
          detected_statuses = []
          @approval_menu    = {}
          cancel_link_key   = :label_cancel

          @easy_attendances.each do |attendance|
            detected_statuses << attendance.approval_status unless detected_statuses.include?(attendance.approval_status)
            cancel_link_key = :label_request_cancel if cancel_link_key != :label_request_cancel && attendance.approved? && !User.current.admin?

            bulk_permissions[:approve]        &&= attendance.easy_attendance_activity && attendance.easy_attendance_activity.approval_required? && attendance.can_approve?
            bulk_permissions[:request_cancel] &&= attendance.can_request_cancel?
            bulk_permissions[:destroy]        &&= attendance.can_delete?
          end
          detected_statuses &= [EasyAttendance::APPROVAL_WAITING, EasyAttendance::CANCEL_WAITING]

          @can              = {
              :edit           => edit_permitted,
              :request_cancel => bulk_permissions[:request_cancel],
              :destroy        => bulk_permissions[:destroy],
              :approve        => bulk_permissions[:approve]
          }
          @cancel_link_text = l(cancel_link_key, :scope => [:easy_attendance]) if @can[:request_cancel]

          if @can[:approve] && detected_statuses.present?
            status         = detected_statuses.count > 1 ? :global : detected_statuses.first
            @approval_menu = {
                :title   => l(status, :scope => [:easy_attendance, :approval, :titles]),
                :actions => l(:actions, :scope => [:easy_attendance, :approval]) }
          end

          render :layout => false
        end

        def projects
          @projects = Project.where(:id => params[:ids]).to_a
          @project  = @projects.first if @projects.count == 1
          @safe_attributes = @projects.map(&:safe_attribute_names).reduce(:&)
          @project_priorities = EasyProjectPriority.active

          if @projects.any?
            @options_by_custom_field = {}
            custom_fields = @projects.first.available_custom_fields
            custom_fields.each do |field|
              values = field.possible_values_options(@projects)
              if values.present?
                @options_by_custom_field[field] = values
              end
            end
          end

          statuses  = @projects.collect(&:status).uniq
          if statuses.count == 1
            case statuses.pop
            when Project::STATUS_ACTIVE
              @all_active = true
            when Project::STATUS_CLOSED
              @all_closed = true
            when Project::STATUS_ARCHIVED
              @all_archived  = true
              @can_unarchive = User.current.admin? && !@projects.any? { |project| project.parent && project.parent.archived? }
            end
          end
          render :layout => false
        end

        def templates
          @templates = Project.templates.sorted.where(:id => params[:ids]).all
          @template  = @templates.first if @templates.count == 1

          render :layout => false
        end

        def easy_rake_tasks
          @tasks    = EasyRakeTask.where(:id => params[:ids]).all
          @task     = @tasks.first if @tasks.count == 1
          @back_url = back_url

          render :layout => false
        end

        def admin_users
          @users    = User.visible.where(:id => params[:ids]).all
          @user_ids = @users.map(&:id).sort
          @user     = @users.first if @users.count == 1
          @back_url = back_url

          render :layout => false
        end

        private

        def time_entries_clear_activities
          unless @projects.blank?
            @activities = [] if @projects.detect { |p| p.fixed_activity? }
          end
        end

        def time_entries_add_issues
          if @project
            @issues = @project.issues.visible.open.order(:subject).limit(25)
          end
        end

        def time_entries_disable_delete_with_easy_attendance
          if @can && (@can[:delete] != false)
            delete_allowed = @time_entries.all? { |t| t.easy_attendance.blank? }
            @can[:delete]  = delete_allowed
          end
        end

        def ensure_time_entry_permissions
          @ids = @time_entries.map(&:id)
          if @can
            @can[:easy_locking]   = @time_entries.all?(&:can_lock?)
            @can[:easy_unlocking] = @time_entries.all?(&:can_unlock?)
          end
        end

      end
    end

    module InstanceMethods

      def issues_with_easy_extensions
        @options = { show_story_points: params[:show_story_points] }
        if (@issues.size == 1)
          @issue = @issues.first
        end
        @issue_ids            = @issues.map(&:id).sort
        @issues_by_created_on = @issues.sort_by(&:created_on)

        if EasySetting.value(:close_subtask_after_parent)
          unselected_children_ids = []
          @issues.each do |issue|
            unselected_children_ids += issue.descendants.pluck(:id)
            unselected_children_ids -= [issue.id]
          end

          @subtasks_to_close = unselected_children_ids.uniq.size
        end

        @can = { :edit         => @issues.all?(&:attributes_editable?),
                 :log_time     => (@project && User.current.allowed_to?(:log_time, @project)),
                 :copy         => User.current.allowed_to?(:copy_issues, @projects) && Issue.allowed_target_projects.any?,
                 :watch        => User.current.logged? && @issues.any? { |issue| issue.author_id != User.current.id && issue.assigned_to_id != User.current.id },
                 :add_watchers => @project && User.current.allowed_to?(:add_issue_watchers, @project),
                 :delete       => @issues.all?(&:deletable?)
        }

        @can[:edit_basic_attrs] = @can[:edit] || (@project && User.current.allowed_to?(:add_issue_notes, @project))

        if @can[:log_time] && @can[:edit] && @issue && EasyIssueTimer.active?(@issue.project)
          timer                     = @issue.easy_issue_timers.where(:user_id => User.current.id).running.last
          @easy_issue_timer_setting = Hash.new
          if timer && !timer.paused?
            @easy_issue_timer_setting[:label]      = l(:button_easy_issue_timer_stop)
            @easy_issue_timer_setting[:url]        = easy_issue_timer_stop_path(@issue, :timer_id => timer)
            @easy_issue_timer_setting[:icon]       = 'icon-checked-circle'
            @easy_issue_timer_setting[:is_running] = true
          else
            @easy_issue_timer_setting[:label] = l((timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume))
            @easy_issue_timer_setting[:url]   = easy_issue_timer_play_path(@issue, :timer_id => timer)
            @easy_issue_timer_setting[:icon]  = 'icon-play'
          end
        end

        @assignables = @issues.map(&:assignable_users).reduce(:&)
        @trackers    = @projects.map { |p| Issue.allowed_target_trackers(p) }.reduce(:&)
        @versions    = @projects.map { |p| p.shared_versions.open }.reduce(:&)
        @priorities  = IssuePriority.active
        @back        = back_url

        @options_by_custom_field = {}
        if @can[:edit]
          custom_fields = @issues.map(&:editable_custom_fields).reduce(:&).reject(&:multiple?)
          custom_fields.each do |field|
            values = field.possible_values_options(@projects)
            if values.present?
              @options_by_custom_field[field] = values
            end
          end
          @allowed_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)
          @versions         = @projects.map { |p| p.shared_versions.open }.reduce(:&).sort
        end
        @easy_distributed_tasks = @issues.detect { |i| i.tracker.easy_distributed_tasks? }.present?

        @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)

        if @safe_attributes.include?('author_id') && @project
          @available_authors = @project.users.active.non_system_flag.sorted.to_a
          @available_authors.push(@issue.author) if @issue && @issue.author && !@available_authors.include?(@issue.author)
          @available_authors
        end

        render :layout => false
      end

      def time_entries_with_easy_extensions
        @time_entries = TimeEntry.where(:id => params[:ids]).
            preload(:project => :time_entry_activities).
            preload(:user).to_a
        return render_404 unless @time_entries.present?

        @users, @projects = [], []
        @time_entries.each do |time_entry|
          @users << time_entry.user
          @projects << time_entry.project
        end

        @users.uniq!
        @projects.uniq!
        @project    = @projects.first if @projects.size == 1
        @time_entry = @time_entries.first if @time_entries.size == 1
        @activities = @projects.map(&:activities).reduce(:&)

        edit_allowed = @time_entries.all? { |t| t.editable_by?(User.current) }
        @can         = { edit: edit_allowed, delete: edit_allowed }
        @back        = back_url

        @options_by_custom_field = {}
        if @can[:edit]
          custom_fields = @time_entries.map(&:editable_custom_fields).reduce(:&).reject(&:multiple?)
          custom_fields.each do |field|
            values = field.possible_values_options(@projects)
            if values.present?
              @options_by_custom_field[field] = values
            end
          end
        end

        render layout: false
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyPatch::ContextMenusControllerPatch'
