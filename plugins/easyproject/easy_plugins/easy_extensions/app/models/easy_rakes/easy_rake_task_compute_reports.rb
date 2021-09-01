class EasyRakeTaskComputeReports < EasyRakeTask

  def settings_view_path
    'easy_rake_tasks/settings/easy_rake_task_compute_reports'
  end

  def execute
    if self.settings['force'] == '1'
      self.settings['force'] = '0'
      self.save
    else
      ers = EasyReportIssueStatus.status_map
    end
    EasyReportIssueStatus.delete_all unless ers
    ers ||= EasyReportSetting.new(name: 'EasyReportIssueStatus', settings: { map: {} })
    last_run = ers.last_run

    max = ers.settings[:map].values.max || -1
    idx = 0
    IssueStatus.sorted.limit(EasyReportIssueStatus::NO_OF_COLUMNS).each do |status|
      next if ers.settings[:map][status.id]
      idx += 1
      idx_increment = max + idx
      break unless idx_increment <= EasyReportIssueStatus::NO_OF_COLUMNS
      ers.settings[:map][status.id] = idx_increment
    end

    ers.last_run = Time.now
    ers.save

    issue_scope = Issue.preload(:easy_report_issue_status, :journals => :details)
    issue_scope = issue_scope.where(["#{Issue.table_name}.updated_on > ?", last_run]) if last_run

    issue_scope.find_each(batch_size: 50) do |issue|

      eris = issue.easy_report_issue_status || issue.build_easy_report_issue_status
      eris.set_all_columns_to_nil

      beginning_time = issue.created_on

      issue.journals.each do |journal|
        detail = journal.details.detect { |d| d.prop_key == 'status_id' }
        next if detail.nil?

        end_time = journal.created_on
        idx      = ers.settings[:map][detail.old_value.to_i]
        next if idx.nil?

        status_duration = eris.get_status_time(idx).to_i
        status_duration += ((end_time - beginning_time) / 60).to_i
        eris.set_status_time(idx, status_duration)

        status_count = eris.get_status_count(idx).to_i
        status_count += 1
        eris.set_status_count(idx, status_count)

        beginning_time = end_time
      end

      eris.save
    end

    true
  end

end
