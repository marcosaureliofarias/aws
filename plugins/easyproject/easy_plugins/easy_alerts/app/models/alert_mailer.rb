class AlertMailer < EasyMailer
  include ActionView::Helpers::SanitizeHelper

  add_template_helper(AlertMailerHelper)
  add_template_helper(EasyQueryHelper)
  add_template_helper(ProjectsHelper)

  def self.send_not_emailed_reports
    all_reports = AlertReport.not_emailed
    all_reports_by_alert = all_reports.preload(:alert, :user).group_by(&:alert)

    all_reports_by_alert.each do |alert, reports|
      if alert.mail_for == 'all'
        reports.group_by(&:user).each do |user, user_reports|
          send_reports_to_user(user, alert, user_reports)
        end
      elsif alert.mail_for == 'group' && alert.mail_group != nil
        alert.mail_group.users.active.each do |user|
          send_reports_to_user(user, alert, select_distinct_reports(reports))
        end
      elsif alert.mail_for == 'custom'
        alert.mail.to_s.split(',').collect(&:strip).select{|k| k.present?}.each do |user_mail|
          send_reports_to_mail(user_mail, alert, select_distinct_reports(reports))
        end
      elsif alert.mail_for == 'assignees'
        if alert.rule.issue_provided?
          reports.group_by(&:entity).each do |issue, issue_reports|
            next unless issue.assigned_to.present?
            send_reports_to_user(issue.assigned_to, alert, issue_reports)
          end
        else
          Rails.logger.error "Alert [#{alert.id}] \"#{alert.name}\" can not report to assignees"
        end
      elsif alert.mail_for == 'coworkers'
        if alert.rule.issue_provided?
          reports.group_by(&:entity).each do |issue, issue_reports|
            issue.watchers.collect(&:user).each do |user|
              send_reports_to_user(user, alert, issue_reports)
            end
          end
        else
          Rails.logger.error "Alert [#{alert.id}] \"#{alert.name}\" can not report to coworkers"
        end
      end
    end
    all_reports.update_all({:emailed => true, :emailed_on => Time.now})
  end

  def self.select_distinct_reports(reports)
    current_entities = []
    reports.select do |r|
      uniq_name = "#{r.entity_type}-#{r.entity_id}"
      if current_entities.include?(uniq_name)
        false
      else
        current_entities << uniq_name
        true
      end
    end
  end

  def self.send_reports_to_user(user, alert, reports)
    return if user.nil? || user.mail_notification == 'none'

    send_reports_to_mail(user.mail, alert, reports)
  end

  def self.send_reports_to_mail(user_mail, alert, reports)
    return if user_mail.blank?

    deliver_method_for_report = (alert.mailer_template_name || "alert_reports_#{alert.rule.name}").to_sym

    x = self.send(:new)  #new is private
    if x.respond_to?(deliver_method_for_report)
      send(deliver_method_for_report, user_mail, alert, reports).deliver
    else
      alert_reports(user_mail, alert, reports).deliver
    end
  end

  def alert_reports(user_mail, alert, reports)
    @alert = alert
    @reports = reports
    @reports_url = url_for(:controller => 'alert_reports', :action => 'index')

    set_query_for_template(alert)

    mail :to => user_mail, :subject => alert.caption
  end

  def alert_reports_timeentry_time_watcher(user_mail, alert, reports)
    @alert = alert
    @reports = reports
    @reports_url = url_for(:controller => 'alert_reports', :action => 'index')
    subjects = l(:'alert_reports_email_subject.timeentry_time_watcher')
    subject = subjects[subjects.keys.sample]
    mail :to => user_mail, :subject => subject
  end

  def alert_reports_timeentry_time_watcher_previous_period_for_all(user_mail, alert, reports)
    @alert = alert
    @period = alert.rule_settings[:time_period] || 'day'
    @reports = reports
    @reports_url = url_for(:controller => 'alert_reports', :action => 'index')

    mail :to => user_mail, :subject => l(:label_timeentry_time_watcher_previous_day_mail_subject)
  end

  def alert_reports_timeentry_time_watcher_previous_period_for_group(user_mail, alert, reports)
    @alert = alert
    @period = alert.rule_settings[:time_period] || 'day'
    @reports = reports.select{|r| !!r.entity}
    @reports_url = url_for(:controller => 'alert_reports', :action => 'index')
    @user_ids = @reports.map{|r| r.entity.id}

    prev_dates = case @period
    when 'day'
      @reports.map{|r| r.entity.today.prev_day}
    when 'week'
      dates = @reports.map{|r| r.entity.today.easy_prev_week(r.entity)}
      [dates.min, dates.max + 6.days]
    end

    if prev_dates
      @minmax = prev_dates.minmax
      time_entries = TimeEntry.where(:user_id => @user_ids, :spent_on => (@minmax[0])..(@minmax[1])).to_a
      @reports_with_time = @reports.map do |report|
        today = report.entity.today
        case @period
        when 'day'
          from = today.prev_day
          to = from
        when 'week'
          from = today.easy_prev_week(report.entity)
          to = from + 6.days
        end
        sum_time_entries = time_entries.sum do |t|
          if (t.user_id == report.entity.id && (from..to).cover?(t.spent_on))
            t.hours
          else
            0
          end
        end

        [report, sum_time_entries, from, to]
      end
      @reports_with_time.sort_by! { |r| r[1]}
    end

    mail :to => user_mail, :subject => alert.caption
  end

  def alert_reports_easy_query_for_all(user_mail, alert, reports)
    @alert = alert
    @reports = reports
    @reports_url = alert_reports_url

    set_query_for_template(alert)

    mail to: user_mail, subject: alert.caption
  end

  def alert_reports_easy_query_for_group(user_mail, alert, reports)
    @alert = alert
    @reports = reports
    @reports_url = alert_reports_url

    set_query_for_template(alert)

    mail to: user_mail, subject: alert.caption
  end

  private

  def set_query_for_template(alert)
    if alert && alert.rule_settings && alert.rule_settings[:query_id]
      @query = EasyQuery.find_by(id: alert.rule_settings[:query_id])
    end
  end

end
