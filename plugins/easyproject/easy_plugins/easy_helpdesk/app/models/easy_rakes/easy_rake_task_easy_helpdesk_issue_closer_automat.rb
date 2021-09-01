class EasyRakeTaskEasyHelpdeskIssueCloserAutomat < EasyRakeTask

  def execute
    issues_closed = 0
    issues_failed = 0
    issues_emails = 0
    errors = []
    auto_update_closers = EasyHelpdeskAutoIssueCloser.all
        .joins(:easy_helpdesk_project)
        .where(easy_helpdesk_projects: { automatically_issue_closer_enable: true })
        .preload(easy_helpdesk_project: :project)
        
    auto_update_closers.find_each(batch_size: 25) do |auto_issue_closer|
      next if auto_issue_closer.easy_helpdesk_project.project.nil?
      issues = auto_issue_closer.easy_helpdesk_project.project.issues
                   .where(status_id: auto_issue_closer.observe_issue_status_id)
                   .where(Issue.arel_table[:updated_on].lteq(Time.now - auto_issue_closer.interval_for_close))
      issues.each do |issue|
        if auto_issue_closer.notify_customer? && issue.easy_email_to.present? && auto_issue_closer.easy_helpdesk_mail_template_id.present?
          mail_template = issue.get_easy_mail_template.from_easy_helpdesk_mail_template(issue, auto_issue_closer.easy_helpdesk_mail_template_id)
          if mail_template.present?
            sender = EasyExtensions::ExternalMailSender.new(issue, mail_template)
            sender.create_journal
            email = sender.send_email
            sender.attach_email(email)
            sender.entity.current_journal.save
            issues_emails += 1
          end
        end

        if auto_issue_closer.change_issue?
          issue.clear_current_journal
          issue.init_journal(User.current, l(:text_isseu_closer_close_notice))
          issue.status_id = auto_issue_closer.done_issue_status_id
          if auto_issue_closer.done_issue_user_id == -1
            issue.assigned_to_id = issue.author_id
          elsif auto_issue_closer.done_issue_user_id != 0
            issue.assigned_to_id = auto_issue_closer.done_issue_user_id
          end

          if issue.save(validate: false)
            issues_closed += 1
          else
            issues_failed += 1
            errors << "##{issue.id} => #{issue.errors.full_messages}"
          end
        end
      end
    end
    if issues_failed.zero?
      if issues_closed.zero? && issues_emails.zero?
        msg = 0
      else
        msg = l(:text_easy_rake_task_helpdesk_issue_closer_updated, updated_count: issues_closed, notified_count: issues_emails)
      end
      return [true, msg]
    else
      return [false, "#{l(:text_easy_rake_task_helpdesk_issue_closer_failed, count: issues_failed, total: issues_closed + issues_failed)} #{errors.uniq.join('; ')}"]
    end
  end

  def category_caption_key
    :easy_helpdesk_name
  end

  def registered_in_plugin
    :easy_helpdesk
  end
end
