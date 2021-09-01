class CreateEasyBaselineJob < EasyActiveJob
  queue_as :default

  def perform(project, user, options = {})
    baseline = project.create_baseline_from_project(options)
    success = false

    Mailer.with_deliveries(false) do
      if baseline.save(validate: false) && baseline.copy(project, only: ['versions', 'issues'], with_time_entries: false)

        # Prevent relations pointing to the baseline
        all_issue_ids = baseline.issues.ids

        from_id_sql = IssueRelation.arel_table[:issue_from_id].in(all_issue_ids)
        to_id_sql = IssueRelation.arel_table[:issue_to_id].in(all_issue_ids)

        IssueRelation.where(from_id_sql.or(to_id_sql)).delete_all

        success = true
      end
    end

    if success
      EasyBaselineMailer.send_notification_about_success(user, baseline).deliver_later
    else
      EasyBaselineMailer.send_notification_with_errors(user, project, baseline.errors.full_messages).deliver_later
    end
  end
end
