class EasyHelpdeskMailHandler < EasyIssueMailHandler

  attr_accessor :easy_helpdesk_project

  def dispatch_to_default
    subject = self.email.subject.to_s
    issue_id = nil
    subject.scan(/#(\d+)/).each do |n|
      begin
        issue_id = n.first.to_i if Issue.joins(:project).where(:id => n.first).where.not(:projects => {:status => [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED]}).exists?
      rescue RangeError
      end
      break unless issue_id.nil?
    end
    if issue_id
      receive_issue_reply(issue_id)
    else
      super
    end
  end

  def target_project
    mailbox_username = handler_options[:easy_helpdesk_mailbox_username] unless handler_options[:easy_helpdesk_mailbox_username].blank?
    @easy_helpdesk_project = EasyHelpdesk::ProjectFinder.by_email(self.email.subject.to_s, self.email.from, self.email.to, mailbox_username)

    target = @easy_helpdesk_project&.project
    target ? target : super
  end

  def callback_receive_issue_before_save(issue)
    super(issue)

    return unless self.easy_helpdesk_project
    issue.easy_helpdesk_mailbox_username = handler_options[:easy_helpdesk_mailbox_username] unless handler_options[:easy_helpdesk_mailbox_username].blank?
    issue.easy_helpdesk_need_reaction = true
  end

  def callback_receive_issue_reply_before_save(issue, journal)
    super(issue, journal)

    response_status_setting = IssueStatus.where(:id => EasySetting.value('easy_helpdesk_client_response_status')).first
    if response_status_setting
      issue.status = response_status_setting
    else
      issue.status = issue.tracker.default_status if !issue.status || issue.status.is_closed?
    end
    issue.easy_helpdesk_need_reaction = true
  end

  def callback_receive_issue_after_build(issue)
    super(issue)
    return unless ehp = self.easy_helpdesk_project
    if ehp.tracker_id
      issue.tracker_id = (issue.project.trackers.find_by(id: ehp.tracker_id) || issue.project.trackers.first).try(:id)
    end
    if ehp.assigned_to_id
      issue.assigned_to_id = issue.project.principals.active.where(id: ehp.assigned_to_id).pluck(:id).first
    end
  end

  # Adds To and Cc as watchers of the given object if the sender has the
  # appropriate permission
  def add_watchers(obj)
    if handler_options[:no_permission_check] || user.allowed_to?("add_#{obj.class.name.underscore}_watchers".to_sym, obj.project)
      mails = []
      mails.concat(Array.wrap(email.to)) if !email.to.blank?
      mails.concat(Array.wrap(email.cc)) if !email.cc.blank? && !EasySetting.value('easy_helpdesk_ignore_cc')
      mails.flatten.reject(&:blank?).collect{|mail| mail.to_s.strip.downcase}.uniq

      unless mails.empty?
        obj.watcher_user_ids = (obj.watcher_user_ids | User.active.having_mail(mails).pluck(:id)) & obj.project.members.pluck(:user_id)
      end
    end
  end

  def mails_from_and_cc_hash(email)
    mails = super(email)

    if EasySetting.value('easy_helpdesk_ignore_cc') && email.cc.present?
      mails[:cc] = []
    end

    mails
  end
end
