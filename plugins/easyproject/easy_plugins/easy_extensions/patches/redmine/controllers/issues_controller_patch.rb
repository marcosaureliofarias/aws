module EasyPatch
  module IssuesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.include(ActionView::Helpers::DateHelper)

      base.class_eval do
        accept_api_auth_actions << :bulk_update

        menu_item :calendar, :only => :calendar
        menu_item :gantt, :only => :gantt

        after_action :extended_flash_notice, :only => [:create, :update]

        include EasyControllersConcerns::DueDateFromVersion

        helper :easy_query
        include EasyQueryHelper
        helper :easy_journal
        include EasyJournalHelper
        helper :easy_ical
        include EasyIcalHelper
        helper :sort
        include SortHelper

        alias_method_chain :new, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :bulk_edit, :easy_extensions
        alias_method_chain :bulk_update, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :retrieve_previous_and_next_issue_ids, :easy_extensions
        alias_method_chain :find_optional_project, :easy_extensions
        alias_method_chain :find_project, :easy_extensions
        alias_method_chain :build_new_issue_from_params, :easy_extensions
        alias_method_chain :update_issue_from_params, :easy_extensions
        alias_method_chain :save_issue_with_child_records, :easy_extensions

        private

        # Rescues an invalid query statement. Just in case...
        def query_statement_invalid(exception)
          session.delete('issue_query')
          super
        end

        def show_all_journals
          params[:journals] == 'all' || !request.format.html?
        end

        def issue_403
          (render_403; return false) unless @issue.editable?
        end

        def extended_flash_notice
          return if @issue.notification_sent != true || @issue.project.nil? || Setting.bcc_recipients? || User.current.mail_notification.blank? || User.current.mail_notification == 'none' || User.current.pref.no_notification_ever || @issue.project.try(:is_planned)

          recipients = if @issue.current_journal
                         @issue.get_notified_users_for_issue_edit.map(&:mail)
                       else
                         @issue.get_notified_users_for_issue_new.map(&:mail)
                       end
          author = @issue.current_journal&.user || @issue.author
          recipients.delete(author.mail) if author&.pref&.no_self_notified

          if !flash[:notice].blank? && recipients.any?
            flash[:notice] += content_tag(:p, l(:label_issue_notice_recipients) + recipients.join('; '), :class => 'email-was-sent')
            flash[:notice] = flash[:notice].html_safe
          end
        end

        def mark_as_read(issue)
          issue.mark_as_read
        end

        def change_back_url_for_external_mails(issue, original_back_url = nil, uploads = [])
          original_back_url ||= params[:back_url]
          original_back_url ||= issue_path(issue)
          if issue.send_to_external_mails == '1'
            url               = issue_preview_external_email_path(id: issue.id, upload_ids: uploads.map(&:id), back_url: original_back_url)
            params[:back_url] = CGI.unescape(url)
          end
        end

        def change_back_url_if_issue_goes_invisible(issue)
          return unless (issue && params[:back_url].nil?)
          if issue.going_invisible?
            params[:back_url] = project_issues_path(issue.project)
            flash[:notice].prepend(view_context.link_to_issue(issue).html_safe + ' - ') unless flash[:notice].blank?
          end
        end

        def prepare_watcher_user_ids_from_params
          if params[:issue][:watcher_user_ids].present? && params[:issue][:watcher_group_ids].present?
            group_user_ids = Group.where(:id => params[:issue][:watcher_group_ids]).joins(:users).distinct.pluck(:user_id)

            params[:issue][:watcher_user_ids].collect(&:to_i) - group_user_ids
          else
            params[:issue][:watcher_user_ids]
          end
        end

        def copy_relations(issues_map)
          relations = IssueRelation.where("relation_type NOT IN (?) AND (issue_from_id IN (?) OR issue_to_id IN (?))", IssueRelation::NOT_COPIED_RELATIONS, issues_map.keys, issues_map.keys)
          relations.each do |r|
            new_relation = r.dup
            if issues_map[new_relation.issue_from_id]
              new_relation.issue_from_id = issues_map[new_relation.issue_from_id]
            end
            if issues_map[new_relation.issue_to_id]
              new_relation.issue_to_id = issues_map[new_relation.issue_to_id]
            end
            unless new_relation.save
              issue_ids = @issue ? "##{@issue.id}" : @issues.map { |i| "##{i.id}" }.join(', ')
              Rails.logger.error "Could not create relation while copying #{issue_ids} from #{new_relation.issue_from_id} to #{new_relation.issue_to_id} with map #{issues_map} due to validation errors: #{new_relation.errors.full_messages.join(', ')}" if Rails.logger
            end
          end
        end

        def parse_params_for_bulk_issue_attributes
          %w(start_date due_date parent_issue_id).each do |attr_name|
            type = params[:issue].delete("#{attr_name}_type")
            if type == 'unchanged'
              params[:issue].delete(attr_name)
            elsif type == 'change_by' && params[:issue][attr_name].present?
              if (offset = params[:issue][attr_name].to_i) && offset.nonzero?
                params[:issue][attr_name] = offset
              else
                params[:issue][attr_name] = 'none'
              end
            elsif type && params[:issue][attr_name].blank?
              params[:issue][attr_name] = 'none'
            end
          end
          params[:issue][:watcher_group_ids] = [nil] if params[:issue][:watcher_user_ids].present?

          parse_params_for_bulk_update(params[:issue])
        end

        def parse_params_for_update
          params['issue']['assigned_to_id'] = '' if params['issue'] && params['issue']['assigned_to_id'] && params['issue']['assigned_to_id'] == 'none'
        end

        def merge_issues
          merge_to = Issue.find_by(:id => params[:issue][:merge_to_id]) if params[:issue]
          return render_404 if merge_to.nil?

          error = true if !merge_to.valid? || !Issue.easy_merge_and_close_issues(@issues, merge_to)

          respond_to do |format|
            format.html do
              if error
                flash[:error] = l(:notice_unsuccessful_merge)
              else
                flash[:notice] = l(:notice_successful_merge, :id => view_context.link_to("##{merge_to.id}", issue_path(merge_to), :title => merge_to.subject)).html_safe
              end
              redirect_back_or_default issue_path(merge_to)
            end
            format.api { error ? render_validation_errors(merge_to) : render_api_ok }
          end
          return
        end

      end
    end

    module InstanceMethods

      def bulk_edit_with_easy_extensions
        @issues.sort!

        @copy  = params[:copy].present?
        @notes = params[:notes]

        if @copy
          unless User.current.allowed_to?(:copy_issues, @projects)
            raise ::Unauthorized
          end
        else
          unless @issues.all?(&:attributes_editable?)
            raise ::Unauthorized
          end
        end

        if params[:issue] && params[:issue][:project_id]
          @target_project = Project.where(Project.allowed_to_condition(User.current, :move_issues)).where(:id => params[:issue][:project_id]).first
          if @target_project
            target_projects = [@target_project]
          end
        end
        target_projects ||= @projects

        @assignables   = target_projects.map(&:assignable_users).reduce(:&)
        @trackers      = target_projects.map { |p| Issue.allowed_target_trackers(p) }.reduce(:&)
        @versions      = target_projects.map { |p| p.shared_versions.open }.reduce(:&)
        @categories    = target_projects.map { |p| p.issue_categories }.reduce(:&)
        @watchers      = User.where(:id => target_projects.map { |p| p.members.collect(&:user_id) }.reduce(:&))
        @time_tracking = target_projects.map { |p| p.module_enabled?(:time_tracking) && User.current.allowed_to?(:view_estimated_hours, p) }.reduce(:&)
        if @copy
          # Copied issues will get their default statuses
          @available_statuses  = []
          @attachments_present = @issues.detect { |i| i.attachments.any? }.present?
          @subtasks_present    = @issues.detect { |i| !i.leaf? }.present?
          @relations_present   = @issues.detect { |i| i.has_relations_to_copy?(true) }.present?
        else
          @available_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)
        end

        @trackers_no_change_allowed = @target_project ? (@issues.map(&:tracker_id).uniq - @trackers.map(&:id)).any? : false

        @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)

        @issue_params = params[:issue] || {}
        @issue_params.each { |k, v| @issue_params.delete(k) if v.blank? }
        @issue_params[:custom_field_values] ||= {}

        @custom_fields = @issues.map do |i|
          i2                 = i.dup
          i2.safe_attributes = @issue_params
          i.editable_custom_fields + i2.editable_custom_fields
        end.reduce(:&).uniq
      end

      def bulk_update_with_easy_extensions
        return merge_issues if params[:merge].present?

        @issues.sort!
        @copy = params[:copy].present?

        attributes       = parse_params_for_bulk_issue_attributes
        copy_subtasks    = (params[:copy_subtasks] == '1')
        copy_attachments = (params[:copy_attachments] == '1')
        copy_relations   = (params[:copy_relations] == '1')

        if @copy
          unless User.current.allowed_to?(:copy_issues, @projects)
            raise ::Unauthorized
          end
          target_projects = @projects
          if attributes['project_id'].present?
            target_projects = Project.where(:id => attributes['project_id']).to_a
          end
          unless User.current.allowed_to?(:add_issues, target_projects)
            raise ::Unauthorized
          end

          if copy_subtasks
            # Descendant issues will be copied with the parent task
            # Don't copy them twice
            @issues.reject! { |issue| @issues.detect { |other| issue.is_descendant_of?(other) } }
          end
        else
          unless @issues.all?(&:attributes_editable?)
            raise ::Unauthorized
          end
        end

        unsaved_issues = []
        saved_issues   = []

        @issues.each do |orig_issue|
          orig_issue.reload
          if attributes[:project_id] && (assigned_to_id = (attributes[:assigned_to_id] || orig_issue[:assigned_to_id]).presence)
            if (assigned = Principal.find_by(id: assigned_to_id))
              assignable = assigned.admin? || assigned.roles.includes(:members).where(:members => { :project_id => attributes[:project_id] }).where(:assignable => true).any?
              unless assignable && assigned.allowed_to?(:view_issues, Project.where(id: attributes[:project_id]).to_a)
                orig_issue.errors.add(:base, l(:error_project_access_permission, assigned.name))
                unsaved_issues << orig_issue
                next
              end
            end
          end

          if attributes[:assigned_to_id]
            orig_issue.validate_change_assignee attributes[:assigned_to_id]
            unless orig_issue.valid?
              unsaved_issues << orig_issue
              next
            end
          end

          if @copy
            issue                            = orig_issue.copy({},
                                                               :attachments => copy_attachments,
                                                               :subtasks    => copy_subtasks,
                                                               :link        => link_copy?(params[:link_copy]),
                                                               copy_parent_issue_id: true
            )
            issue.attributes_for_descendants = attributes.dup
          else
            issue = orig_issue
          end
          issue.init_journal(User.current, params[:notes])
          safe_attributes  = attributes.dup
          restricted_attrs = safe_attributes.keys - orig_issue.safe_attribute_names
          if restricted_attrs.present? && !(User.current.admin? && EasySetting.value('skip_workflow_for_admin', issue.project))
            restricted_attrs.each do |attr|
              orig_issue.errors.add(attr, l(:error_not_a_safe_attribute))
            end
            unsaved_issues << orig_issue
            next
          end
          # moving dates
          if attributes['start_date'].is_a?(Numeric)
            days             = safe_attributes.delete('start_date').days
            issue.start_date = issue.start_date + days if issue.start_date
          end
          if attributes['due_date'].is_a?(Numeric)
            days           = safe_attributes.delete('due_date').days
            issue.due_date = issue.due_date + days if issue.due_date
          end
          issue.safe_attributes = safe_attributes
          if issue.start_date && issue.due_date && issue.start_date > issue.due_date
            if attributes.has_key?('start_date')
              issue.due_date = issue.start_date
            else
              issue.start_date = issue.due_date
            end
          end

          call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
          begin
            saved = issue.save
          rescue ActiveRecord::StaleObjectError
            issue.reload
            issue.safe_attributes = attributes.dup
            saved                 = issue.save
          end
          if saved
            saved_issues << issue
            call_hook(:controller_issues_bulk_edit_after_save, { :params => params, :issue => issue })
          else
            # Keep unsaved issue ids to display them in flash error
            unsaved_issues << orig_issue
          end
        end

        if @copy && copy_relations
          relations_map = {}
          saved_issues.each do |i|
            relations_map.merge!(i.copied_issue_ids) if i.copied_issue_ids
          end
          copy_relations(relations_map)
        end

        if unsaved_issues.empty?
          respond_to do |format|
            format.html do
              flash[:notice] = l(:notice_successful_update) unless saved_issues.empty?
              if params[:follow]
                if @issues.size == 1 && saved_issues.size == 1
                  redirect_to issue_path(saved_issues.first)
                elsif saved_issues.map(&:project).uniq.size == 1
                  redirect_to project_issues_path(saved_issues.map(&:project).first)
                end
              else
                redirect_back_or_default _project_issues_path(@project)
              end
            end
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html do
              @saved_issues   = @issues
              @unsaved_issues = unsaved_issues
              @issues         = Issue.visible.where(:id => @unsaved_issues.map(&:id)).to_a
              bulk_edit
              render :action => 'bulk_edit'
            end
            format.api { render_validation_errors(unsaved_issues) }
          end
        end
      end

      def index_with_easy_extensions
        retrieve_query(EasyIssueQuery)
        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns.merge('tree' => 'issues.root_id asc, issues.lft asc'))
        @query.open_categories_ids       = params[:easy_query][:open_categories_ids] if params[:easy_query] && !params[:easy_query][:export_all_groups]
        @query.count_on_different_column = params[:easy_query][:count_on_different_column] if params[:easy_query]
        @query.add_additional_scope(@project && @project.easy_is_easy_template? ? Project.templates : Project.non_templates)

        if @query.valid?
          if [:xlsx, :csv, :pdf].include?(request.format.to_sym) && params[:export_description].present?
            if params[:export_description] == '1'
              @query.column_names = @query.columns.map(&:name) + [:description] unless @query.has_column?(:description)
            else
              @query.column_names.delete(:description)
            end
          end

          @issues      = prepare_easy_query_render
          @issue_count = @entity_count

          if request.xhr? && !@issues
            render_404
            return false
          end

          respond_to do |format|
            format.html {
              if @issues # list output
                project_ids = []
                if !@query.grouped? || (loading_group? && !loading_multiple_groups?(@query))
                  project_ids = @issues.collect(&:project_id)
                elsif @query.grouped? && loading_multiple_groups?(@query)
                  @issues.each { |key, entities| project_ids.concat(entities.collect(&:project_id)) }
                end
                User.current.preload_membership_for(project_ids)
              end
              render_easy_query_html
            }
            format.api {
              if include_in_api_response?('spent_time')
                Issue.load_visible_spent_hours(@entities)
                Issue.load_visible_total_spent_hours(@entities)
              end
              if include_in_api_response?('total_estimated_time')
                Issue.load_visible_total_estimated_hours(@entities)
              end
              Issue.load_visible_relations(@entities) if include_in_api_response?('relations')
            }
            format.atom { render_feed(@entities, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
            format.csv {
              send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query))
            }
            format.xlsx { render_easy_query_xlsx }
            format.pdf { render_easy_query_pdf }
            format.ics { send_data(issues_to_ical(@entities), :filename => get_export_filename(:ics, @query), :type => Mime[:ics].to_s + '; charset=utf-8') }
          end
        else
          respond_to do |format|
            format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
            format.any(:atom, :csv, :pdf, :ics) { head :ok }
            format.api { render_validation_errors(@query) }
          end
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def show_with_easy_extensions
        @journals, @journal_count = @issue.prepare_journals(User.current.wants_comments_in_reverse_order?, show_all_journals)
        @journal_limit            = show_all_journals ? @journal_count : EasySetting.value('easy_extensions_journal_history_limit')
        mark_as_read(@issue)

        @relations = @issue.relations.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? }

        if User.current.allowed_to?(:view_time_entries, @project)
          Issue.load_visible_spent_hours([@issue])
          Issue.load_visible_total_spent_hours([@issue])
        end

        if User.current.allowed_to?(:view_estimated_hours, @project)
          Issue.load_visible_total_estimated_hours([@issue])
        end

        respond_to do |format|
          format.html {
            retrieve_previous_and_next_issue_ids
            render :template => 'issues/show' }
          format.api do
            @textilizable = params[:textilizable]
            @changesets   = @issue.changesets.visible.preload(:user) if include_in_api_response?('changesets')
          end
          format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
          format.pdf { send_file_headers! :type => 'application/pdf', :filename => "#{@issue.to_s}.pdf" }
          format.ics { send_data(issue_to_ical(@issue), :filename => "#{@issue.to_s}.ics", :type => Mime[:ics].to_s + '; charset=utf-8') }
          format.qr {
            @easy_qr = EasyQr.generate_qr(issue_url(@issue))
            if request.xhr?
              render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
            else
              render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
            end
          }
        end

      end

      def edit_with_easy_extensions
        parse_params_for_update

        return unless update_issue_from_params
        if params[:issue] && params[:issue][:private_notes]
          @issue.private_notes = params[:issue][:private_notes].to_s.to_boolean
        elsif EasySetting.value('issue_private_note_as_default', @project)
          @issue.private_notes = EasySetting.value('issue_private_note_as_default', @project)
        end
        set_due_date_from_version

        call_hook(:controller_easy_issues_edit, { :issue => @issue, :params => params })

        respond_to do |format|
          format.html { render(partial: 'edit', :layout => false) if request.xhr? }
          format.xml {}
          format.js { render :layout => !request.xhr? }
        end
      end

      def update_with_easy_extensions
        parse_params_for_update

        return unless update_issue_from_params

        uploaded_files = @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))

        saved = false
        begin
          saved = save_issue_with_child_records
        rescue ActiveRecord::StaleObjectError
          @conflict = true
          if params[:last_journal_id]
            @conflict_journals = @issue.journals_after(params[:last_journal_id]).to_a
          else
            @conflict_journals = [@issue.journals.last].compact
          end
          @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
        end

        if saved
          render_attachment_warning_if_needed(@issue)
          respond_to do |format|
            format.html {
              if @issue.current_journal.persisted?
                flash[:notice]         = l(:notice_successful_update)
                uploaded_files[:files] ||= []
                uploaded_files[:files].concat(@issue.current_journal.stripped_images || []) if @issue.current_journal.respond_to?(:stripped_images)
              end
              call_hook(:controller_issues_after_successful_update, { issue: @issue, uploaded_files: uploaded_files })

              flash[:warning] = safe_join(@issue.errors.full_messages.flatten, '<br>'.html_safe) if @issue.errors.any?
              change_back_url_for_external_mails(@issue, nil, uploaded_files[:files])
              change_back_url_if_issue_goes_invisible(@issue)
              redirect_back_or_default issue_path(@issue)
            }
            format.api do
              response.headers['X-Easy-Lock-Version']    = @issue.lock_version.to_s
              response.headers['X-Easy-Last-Journal-Id'] = @issue.last_journal_id.to_s
              render_api_ok
            end
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit', :layout => !request.xhr?, :status => :unprocessable_entity }
            format.api do
              if @conflict
                @issue.errors.add :base, l(:notice_issue_update_conflict)
              end
              if @conflict_journals.present?
                sanitizer = Rails::Html::FullSanitizer.new
                journal   = @conflict_journals.max_by(&:id)
                msg       = sanitizer.sanitize(l(:label_updated_datetime_by,
                                                 author:   journal.user,
                                                 datetime: format_time(journal.created_on)
                                               ))
                @issue.errors.add :base, msg
              end
              render_validation_errors(@issue)
            end
          end
        end
      end

      def create_with_easy_extensions
        unless User.current.allowed_to?(:add_issues, @issue.project, :global => true)
          raise ::Unauthorized
        end
        start_issue_timer_now                  = params[:easy_issue_timer_start_now].presence
        @issue.description                     ||= ''
        @issue.update_repeat_entity_attributes = true
        if params[:subtask_for_id] && Issue.visible(User.current).exists?(params[:subtask_for_id].to_i)
          @issue.parent_issue_id = params[:subtask_for_id]
        end
        call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        @issue.watcher_user_ids = prepare_watcher_user_ids_from_params if params[:issue]

        if @issue.save
          copy_relations(@issue.copied_issue_ids) if @copy_relations && @issue.copied_issue_ids
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue })
          mark_as_read(@issue)

          if start_issue_timer_now && EasyIssueTimer.active?(@issue.project)
            EasyIssueTimer.transaction do
              @easy_issue_timer ||= @issue.easy_issue_timers.build(:user => User.current, :start => DateTime.now)
              @easy_issue_timer.play!
              @easy_issue_timer.save!

              EasyIssueTimer.where.not(:id => @easy_issue_timer.id).where(:user_id => User.current.id).each do |t|
                t.pause!
              end
            end
          end

          respond_to do |format|
            format.html {
              if params[:for_dialog]
                render :plain => @issue.id
              else
                render_attachment_warning_if_needed(@issue)
                flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("#{@issue.to_s}", issue_path(@issue), :title => @issue.subject)).html_safe

                if params[:continue]
                  next_url = new_issue_path(:project_id => @project, :issue => { :tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id, :subtask_for_id => @issue.parent_issue_id }.reject { |_, v| v.nil? })
                else
                  next_url = issue_path(@issue)
                end
                change_back_url_for_external_mails(@issue, url_for(next_url))
                redirect_back_or_default(next_url)
              end
            }
            format.js
            format.api { render :action => 'show', :status => :created, :location => issue_url(@issue) }
          end
        else
          respond_to do |format|
            format.html do
              if params[:for_dialog]
                render :partial => 'easy_issues/new_for_dialog'
              else
                render :controller => 'issues', :action => 'new'
              end
            end
            format.js
            format.api { render_validation_errors(@issue) }
          end
        end
      end

      def new_with_easy_extensions
        future_parent_issue = Issue.visible(User.current).find_by(id: params[:subtask_for_id]) if params[:subtask_for_id]
        if future_parent_issue
          # Maybe we could write some UI for this feature
          attributes_for_inheritance = [:fixed_version_id]
          attributes_for_inheritance.each do |attribute|
            @issue.send("#{attribute}=", future_parent_issue.send(attribute)) unless params[:issue]
          end
        end
        if @project && @project.start_date && Setting.default_issue_start_date_to_creation_date? && !EasySetting.value('project_calculate_start_date') && Date.today < @project.start_date
          @issue.start_date = @project.start_date
        end
        if !@issue.activity_id && @project && @project.fixed_activity? && TimeEntryActivity.default
          @issue.activity_id = TimeEntryActivity.default.id
        end
        set_due_date_from_version
        new_without_easy_extensions
      end

      def destroy_with_easy_extensions
        raise Unauthorized unless @issues.all?(&:deletable?)

        # all issues and their descendants are about to be deleted
        issues_and_descendants_ids = Issue.self_and_descendants(@issues).pluck(:id)
        time_entries               = TimeEntry.where(:issue_id => issues_and_descendants_ids)
        @hours                     = time_entries.sum(:hours).to_f

        if @hours > 0
          case params[:todo]
          when 'destroy'
            time_entries.each do |time_entry|
              unless time_entry.valid_for_destroy?
                flash.now[:error] = l(:error_could_not_delete_time_entries_on_the_task)
                return
              end
            end
          when 'nullify'
            if Setting.timelog_required_fields.include?('issue_id')
              flash.now[:error] = l(:field_issue) + " " + ::I18n.t('activerecord.errors.messages.blank')
              return
            else
              time_entries.update_all(:issue_id => nil)
            end
          when 'reassign'
            reassign_to = @project && @project.issues.find_by_id(params[:reassign_to_id]) if params[:reassign_to_id]
            if reassign_to.nil?
              if api_request?
                render_api_errors(l(:error_hours_reassigned, hours: @hours))
              else
                flash.now[:error] = l(:error_issue_not_found_in_project)
              end
              return
            elsif issues_and_descendants_ids.include?(reassign_to.id)
              if api_request?
                render_api_errors(l(:error_cannot_reassign_time_entries_to_an_issue_about_to_be_deleted))
              else
                flash.now[:error] = l(:error_cannot_reassign_time_entries_to_an_issue_about_to_be_deleted)
              end
              return
            else
              time_entries.update_all(:issue_id => reassign_to.id, :project_id => reassign_to.project_id)
            end
          else
            # display the destroy form if it's a user request
            return unless api_request?
          end
        end
        @issues.each do |issue|
          begin
            issue.reload.destroy
          rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
            # nothing to do, issue was already deleted (eg. by a parent)
          end
        end
        respond_to do |format|
          format.html { redirect_back_or_default(@project ? project_issues_path(@project) : issues_path) }
          format.api { render_api_ok }
        end
      end

      def retrieve_previous_and_next_issue_ids_with_easy_extensions
        return #speed boost, low used feature
        retrieve_query_from_session(EasyIssueQuery)
        if @query
          sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
          sort_update(@query.sortable_columns, 'issues_index_sort')
          limit     = 500
          issue_ids = @query.entities_ids(:order => sort_clause, :limit => (limit + 1), :include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
          if (idx = issue_ids.index(@issue.id)) && idx < limit
            if issue_ids.size < 500
              @issue_position = idx + 1
              @issue_count    = issue_ids.size
            end
            @prev_issue_id = issue_ids[idx - 1] if idx > 0
            @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
            @prev_issue    = Issue.where(:id => @prev_issue_id).select([:id, :subject, :project_id]).first if @prev_issue_id
            @next_issue    = Issue.where(:id => @next_issue_id).select([:id, :subject, :project_id]).first if @next_issue_id
          end
        end
      end

      def find_optional_project_with_easy_extensions
        #easy query workaround
        return if params[:set_filter] == '1' && params[:project_id] && /\A(=|\!|\!\*|\*)\S*/.match?(params[:project_id])
        if !params[:project_id] && (params[:issue] && params[:issue][:project_id])
          params[:project_id] = params[:issue][:project_id]
        end
        find_optional_project_without_easy_extensions
      end

      def find_project_with_easy_extensions(project_id = params[:id])
        project_id ||= params[:issue] && params[:issue][:project_id]
        @project   = Project.find(project_id)
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def build_new_issue_from_params_with_easy_extensions
        parse_params_for_update
        if build_new_issue_from_params_without_easy_extensions
          available_trackers = @issue.project ? @issue.allowed_target_trackers : []
          if params[:issue] && !params[:issue].key?(:tracker_id) && @issue.tracker && available_trackers.present? && available_trackers.exclude?(@issue.tracker)
            @issue.tracker = available_trackers.first
          end
          @copy_relations = params[:copy_relations].present? ? params[:copy_relations].to_boolean : request.get?
          @copy_subtasks  = params[:copy_subtasks].present? ? params[:copy_subtasks].to_boolean : request.get?
        end
      end

      def update_issue_from_params_with_easy_extensions
        @issue.validate_change_assignee(params[:issue][:assigned_to_id]) if params[:validate_assignee] && params[:issue][:assigned_to_id]
        return false unless update_issue_from_params_without_easy_extensions
        @time_entry.activity = @issue.activity if EasySetting.value(:project_fixed_activity, @project) && @issue.activity
        @time_entry.user     ||= User.current
        true
      end

      def save_issue_with_child_records_with_easy_extensions
        Issue.transaction do
          if time_entry_params? && User.current.allowed_to?(:log_time, @issue.project)
            time_entry                 = @time_entry || TimeEntry.new
            time_entry.project         = @issue.project
            time_entry.issue           = @issue
            time_entry.user            = User.current
            time_entry.spent_on        = User.current.today
            time_entry.safe_attributes = params[:time_entry]
            @issue.time_entries << time_entry
          end

          call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal })
          if @issue.save
            call_hook(:controller_issues_edit_after_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal })
          else
            raise ActiveRecord::Rollback
          end
        end
      end

      def time_entry_params?
        params[:time_entry] &&
            (
            params[:time_entry][:hours].present? ||
                params[:time_entry][:comments].present? ||
                params[:time_entry][:hours_hour].present? ||
                params[:time_entry][:hours_minute].present? ||
                params[:time_entry][:easy_time_entry_range] && (
                params[:time_entry][:easy_time_entry_range][:from].present? ||
                    params[:time_entry][:easy_time_entry_range][:to].present?
                )
            )
      end

    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyPatch::IssuesControllerPatch'
