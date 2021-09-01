class EasyMailer < EasyBlockMailer

  def easy_attendance_added(email, easy_attendances)
    @easy_attendances = easy_attendances
    @easy_attendance  = @easy_attendances.first
    @user             = @easy_attendance.user
    @from             = @easy_attendances.map(&:arrival).compact.min
    @to               = @easy_attendances.map(&:departure).compact.max || @from
    mail :to => email, :subject => l(:'easy_attendance.mail_added.subject', :user => @user.name)
  end

  def easy_attendance_updated(email, easy_attendances)
    @easy_attendances = easy_attendances
    @easy_attendance  = @easy_attendances.first
    @user             = @easy_attendance.user
    @from             = @easy_attendances.map(&:arrival).compact.min
    @to               = @easy_attendances.map(&:departure).compact.max || @from
    mail :to => email, :subject => l(:'easy_attendance.mail_updated.subject', :user => easy_attendances.first.user.name)
  end

  def easy_attendance_approval_send_mail_pending(email, easy_attendances)
    return if easy_attendances.blank?
    @min              = easy_attendances.map(&:arrival).compact.min
    @max              = easy_attendances.map(&:departure).compact.max || @min
    @reciever         = email
    @easy_attendances = easy_attendances.group_by { |x| [x.user.name, x.easy_attendance_activity.name] }
    @any_canceled     = easy_attendances.any?(&:cancel_waiting?)
    activity          = @easy_attendances.keys.map { |x| x[1] }
    activity          = join_attributes(activity)
    users             = @easy_attendances.keys.map { |x| x[0] }
    users             = join_attributes(users)
    mail to: email, subject: l(:'easy_attendance.mail_approval_new_pending_subject', user_name: users, activity: activity)
  end

  def easy_attendance_send_mail_approval_result(email, easy_attendances, notes)
    return if easy_attendances.blank?
    @notes            = notes
    @min              = easy_attendances.map(&:arrival).compact.min
    @max              = easy_attendances.map(&:departure).compact.max || @min
    @reciever         = email
    status            = easy_attendances.collect { |attendance| attendance.attendance_status }.uniq.join('/')
    @easy_attendances = easy_attendances.group_by { |x| x.easy_attendance_activity.name }
    activity          = @easy_attendances.keys
    activity          = join_attributes(activity)
    mail to: email, subject: l(:'easy_attendance.mail_approval_new_response_subject', activity: activity, status: status)
  end

  def easy_attendance_send_mail_approval_result_admin(email, easy_attendances, notes, approving_user)
    return if easy_attendances.blank?
    @notes            = notes
    @approved_by      = approving_user
    @min              = easy_attendances.map(&:arrival).compact.min
    @max              = easy_attendances.map(&:departure).compact.max || @min
    @reciever         = email
    status            = easy_attendances.collect { |attendance| attendance.attendance_status }.uniq.join('/')
    @easy_attendances = easy_attendances.group_by { |x| x.easy_attendance_activity.name }
    activity          = @easy_attendances.keys
    activity          = join_attributes(activity)
    mail to: email, subject: l(:'easy_attendance.mail_approval_new_response_subject_admin', activity: activity, status: status, user_list: easy_attendances.map(&:user).uniq.map(&:to_s).join(', '))
  end


  def easy_attendance_send_mail_delete_attendances(email, easy_attendances)
    return if easy_attendances.blank?
    @min              = easy_attendances.map(&:arrival).compact.min
    @max              = easy_attendances.map(&:departure).compact.max || @min
    status            = easy_attendances.collect { |attendance| attendance.attendance_status }.uniq.join('/')
    @easy_attendances = easy_attendances.group_by { |x| x.easy_attendance_activity.name }
    activity          = @easy_attendances.keys
    activity          = join_attributes(activity)
    mail to: email, subject: l(:'easy_attendance.mail_delete_attendance_subject', activity: activity, status: status)
  end

  def easy_attendance_user_arrival_notify(model)
    @user                                = model.user
    @recipient                           = model.notify_to
    @easy_attendance_user_arrival_notify = model

    mail(:to => @recipient.mail, :subject => l(:text_easy_attendance_user_notify_default_message, :user => @user))
  end

  def easy_rake_task_check_failure_tasks(task, failed_tasks)
    @task         = task
    @failed_tasks = failed_tasks

    mail :to => task.recepients, :subject => task.caption
  end

  def easy_query_copied_notify(emails, query, author = nil)
    author ||= User.current

    @query       = query
    @author_name = author.name

    mail :to => emails, :subject => l(:text_new_easy_query_subject, :query => @query.name)
  end

  def internal_error(email, message, attachment_path)
    @message                  = message
    attachments['error.html'] = File.read(attachment_path)
    mail(to: email, from: User.current.mail, subject: "Internal Error - #{%x(hostname).strip}",)
  end

  private

  def join_attributes(attributes)
    return attributes.join(', ') if attributes && attributes.is_a?(Array)
    attributes
  end

end
