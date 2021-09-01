# Preview all emails at http://localhost:3000/rails/mailers/
class MailerPreview < ActionMailer::Preview

  def alert_reports
    User.current.as_admin do
      AlertMailer.alert_reports(User.current, Alert.last, AlertReport.limit(10).to_a)
    end
  end

  def alert_reports_easy_query_for_all
    User.current.as_admin do
      alert = Alert.find(35)
      AlertMailer.alert_reports_easy_query_for_all(User.current, alert, alert.reports.limit(100).to_a)
    end
  end

end
