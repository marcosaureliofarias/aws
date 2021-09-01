class EasyLockNotifier < EasyBlockMailer

  def notify_admins(user, locking_time, options = {})
    @user = user
    @locking_time = locking_time
    @options = options
    send_to = User.admin.active
    send_to = send_to.where(id: EasySetting.value('lock_admins_to_notify')) if EasySetting.value('notify_all_admins').to_boolean
    mail(to: send_to, subject: l('security_user_lock.mail_subject', user_name: user.name))
  end

end
