module EasyHelpdesk
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_sidebar_project_info_attributes_bottom, :partial => 'sidebar/easy_helpdesk_view_sidebar_project_info_attributes_bottom'
    render_on :view_sidebar_project_info_links_bottom_new_box, :partial => 'sidebar/easy_helpdesk_view_sidebar_project_info_links_bottom_new_box'
    render_on :view_issue_sidebar_issue_details_table_bottom, :partial => 'sidebar/easy_helpdesk_view_issue_sidebar_issue_details_table_bottom'
    render_on :view_issues_bulk_edit_details_bottom, partial: 'issues/easy_helpdesk_bulk_edit_details'
    render_on :easy_user_type_visibility_options_bottom, partial: 'easy_user_types/hide_sla_data'
    render_on :view_user_preferences_form_bottom, partial: 'users/sla_data_pref'
    render_on :view_users_bulk_edit, partial: 'users/bulk_edit_sla_data_pref'

    def view_issues_show_details_bottom(context = {})
      return if !context[:issue].maintained_by_easy_helpdesk?
      context[:controller].send(:render_to_string, partial: 'issues/easy_helpdesk_view_issues_show_details_bottom', locals: context)
    end

    def view_easy_external_emails_preview_external_email(context={})
      entity = context[:entity]
      return if !entity.is_a?(Issue) || !entity.maintained_by_easy_helpdesk?
      context[:controller].send(:render_to_string, :partial => 'easy_external_emails/easy_helpdesk_preview_external_email', :locals => context)
    end

    def view_gantts_show_api_issue(context={})
      api, issue = context[:api], context[:issue]

      return if issue.status.is_closed? || issue.easy_due_date_time.blank?

      total_seconds = issue.easy_due_date_time - issue.created_on
      seconds_from_start = Time.now.utc - issue.easy_due_date_time
      current_percent_to_end = seconds_from_start / total_seconds * 100

      if Time.now.utc >= issue.easy_due_date_time
        css_classes = 'easy-helpdesk-sla-violated'
      elsif current_percent_to_end >= 75.0
        css_classes = 'easy-helpdesk-sla-almost-violated'
      else
        #css_classes = 'easy-helpdesk-sla-ok'
      end

      api.css_classes(css_classes)
    end

    def view_projects_form(context={})
      project = context[:project]

      return unless EasyHelpdeskProject.exists?(project_id: project.id)
      return unless EasySetting.value('easy_helpdesk_allow_custom_sender')

      to_return = ''

      # Custom sender
      to_return << '<p>'
      to_return << label_tag('easy_setting_easy_helpdesk_custom_sender', l(:setting_easy_helpdesk_custom_sender))
      to_return << email_field_tag('easy_setting[easy_helpdesk_custom_sender]', EasySetting.value('easy_helpdesk_custom_sender', project))
      to_return << content_tag(:em, l(:text_easy_helpdesk_custom_sender))
      to_return << '</p>'

      to_return.html_safe
    end

    def controller_easy_issues_edit(context={})
      project = context[:project]

      return unless EasyHelpdeskProject.exists?(project_id: project.id)

      issue = context[:issue]
      issue.easy_helpdesk_need_reaction = false
    end

    def controller_issues_after_successful_update(context = {})
      issue = context[:issue]
      return if !issue.maintained_by_easy_helpdesk?
      return if issue.easy_email_to.presence.nil?

      easy_helpdesk_mail_template = context[:hook_caller].params.dig(:issue, :easy_helpdesk_mail_template).presence
      return if easy_helpdesk_mail_template.nil?

      # dont redirect to preview if checked both options
      issue.send_to_external_mails = nil

      files = context[:uploaded_files][:files] || []
      @journal = issue.journals.last
      
      mail_template = issue.get_easy_mail_template.from_easy_helpdesk_mail_template(issue, easy_helpdesk_mail_template)
      return if mail_template.nil?

      EasyExtensions::ExternalMailSender.call(issue, mail_template, journal: @journal, attachments: files)

      EasySlaEvent.create_easy_sla_event(issue)

      notices = context[:hook_caller].flash[:notice].to_s.split('<br>'.html_safe)
      notices << l(:notice_email_sent, value: mail_template.mail_recepient)
      context[:hook_caller].flash[:notice] = safe_join(notices, '<br>'.html_safe) if notices.any?
    end

    def controller_easy_external_emails_after_save(context = {})
      issue = context[:entity]
      EasySlaEvent.create_easy_sla_event(issue) if issue.is_a?(Issue) && issue.maintained_by_easy_helpdesk? 
    end

    def view_issues_form_details_bottom(context={})
      project = context[:project]

      return unless EasyHelpdeskProject.exists?(project_id: project.id)

      context[:controller].send(:render_to_string, :partial => 'issues/easy_helpdesk_view_issues_form_details_bottom', :locals => context)
    end

    def view_issues_show_top_contextual_before_progress(context={})
      project = context[:project]

      return unless EasyHelpdeskProject.exists?(project_id: project.id)

      context[:controller].send(:render_to_string, :partial => 'issues/easy_helpdesk_view_issues_show_top_contextual_before_progress', :locals => context)
    end

    def helper_easy_issue_query_beginning_buttons(context={})
      issue = context[:issue]
      s = context[:content]

      if issue.easy_helpdesk_need_reaction?
        s << content_tag(:i, '', :class => 'icon-warning red', :title => l(:label_easy_helpdesk_need_reaction))
      end
    end

    def helper_project_settings_tabs(context={})
      if context[:project].easy_helpdesk_project && User.current.allowed_to?(:manage_easy_helpdesk_project, context[:project] )
        context[:tabs] << {:name => 'helpdesk', :action => :helpdesk, :partial => 'projects/settings/helpdesk', :label => :label_easy_helpdesk_project_helpdesk_tab, :no_js_link => true}
      end
    end

    def application_helper_options_for_period_select_bottom(context={})
      context[:custom_items].unshift([l(:label_to_now), 'to_now']) if eqeoc(:to_now, context[:field], context[:options])
    end
  end
end
