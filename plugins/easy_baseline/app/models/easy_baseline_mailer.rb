class EasyBaselineMailer < Mailer
  include Redmine::I18n

  def send_notification_about_success(user, baseline)
    @baseline = baseline
    subject = l(:title_baseline_successfully_created, project_name: baseline.name)

    mail to: user.mail, subject: subject
  end

  def send_notification_with_errors(user, project, validation_errors)
    @validation_errors = validation_errors
    subject = l(:title_baseline_from_project_not_created_with_errors, project_name: project.name)

    mail to: user.mail, subject: subject
  end

end
