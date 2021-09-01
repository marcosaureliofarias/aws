module EasyHelpdeskProjectsHelper

  def unused_mailbox_for_helpdesk_projects(easy_helpdesk_project)
    mailboxes = EasyRakeTaskEasyHelpdeskReceiveMail.find_mailboxes_non_default.to_a
    if !easy_helpdesk_project.default_for_mailbox.nil? && !mailboxes.include?(easy_helpdesk_project.default_for_mailbox)
      mailboxes << easy_helpdesk_project.default_for_mailbox
    end
    mailboxes.sort_by{|m| m.username_caption.to_s.strip}
  end

  def render_non_default_mailboxes_warning_if_needed
    unused = EasyRakeTaskEasyHelpdeskReceiveMail.find_mailboxes_non_default.active
    return if unused.empty?
    s = "<div class=\"flash warning\"><span>#{l(:text_easy_helpdesk_non_default_mailboxes_warning_top)}<br><b>"
    s << unused.collect(&:username_caption).join(', ')
    s << "</b><br>#{l(:text_easy_helpdesk_non_default_mailboxes_warning_below)}</span></div>"
    s.html_safe
  end

  def aggregated_hours_periods
    [
      [l(:'aggregated_periods.quarterly'), 'quarterly'],
      [l(:'aggregated_periods.half-yearly'), 'half-yearly'],
      [l(:'aggregated_periods.yearly'), 'yearly']
    ]
  end

  # need to keep compatibility with old API format
  def render_auto_issue_closers(easy_helpdesk_project)
    issue_closers = easy_helpdesk_project.easy_helpdesk_auto_issue_closers
                      .pluck(:observe_issue_status_id, :done_issue_status_id, :inactive_interval)

    issue_closers.map{ |closer| [closer.first, closer.second, closer.third.to_s] }.flatten
  end
end
