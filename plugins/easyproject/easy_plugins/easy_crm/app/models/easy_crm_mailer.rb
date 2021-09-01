class EasyCrmMailer < Mailer

  def self.deliver_easy_crm_case_added(easy_crm_case)
    users = easy_crm_case.notified_users | easy_crm_case.notified_watchers
    users.each do |user|
      easy_crm_case_added(user, easy_crm_case).deliver_later
    end
  end

  def easy_crm_case_added(user, easy_crm_case)
    return if easy_crm_case.project && (easy_crm_case.project.easy_is_easy_template? || easy_crm_case.project.status == Project::STATUS_PLANNED)
    @author = easy_crm_case.author # redmine inner logic in "mail" function
    return if @author && @author.pref.no_notification_ever

    redmine_headers 'Project' => easy_crm_case.project.identifier,
      'EasyCrmCase-Id' => easy_crm_case.id,
      'EasyCrmCase-Author' => easy_crm_case.author.login
    redmine_headers 'EasyCrmCase-Assignee' => easy_crm_case.assigned_to.login if easy_crm_case.assigned_to
    redmine_headers 'EasyCrmCase-ExternalAssignee' => easy_crm_case.external_assigned_to.login if easy_crm_case.external_assigned_to
    message_id easy_crm_case
    references easy_crm_case
    @easy_crm_case = easy_crm_case
    @easy_crm_case_url = easy_crm_case_url(easy_crm_case)

    if user == easy_crm_case.assigned_to
      subject_key = 'mail.subject.my_easy_crm_case_add'
    else
      subject_key = 'mail.subject.easy_crm_case_add'
    end

    subject = l(subject_key,
      status: easy_crm_case.easy_crm_case_status.name,
      name: easy_crm_case.name,
      projectname: easy_crm_case.project.family_name(separator: ' > '))

    mail to: user, subject: subject
  end

  def self.deliver_easy_crm_case_updated(journal)
    easy_crm_case = journal.journalized
    users = easy_crm_case.notified_users | easy_crm_case.notified_watchers
    users.each do |user|
      easy_crm_case_updated(user, journal).deliver_later
    end
  end

  def easy_crm_case_updated(user, journal)
    easy_crm_case = journal.journalized
    return if easy_crm_case.project && (easy_crm_case.project.easy_is_easy_template? || easy_crm_case.project.status == Project::STATUS_PLANNED)
    @author = journal.user # redmine inner logic in "mail" function
    return if @author && @author.pref.no_notification_ever

    redmine_headers 'Project' => easy_crm_case.project.identifier,
      'EasyCrmCase-Id' => easy_crm_case.id,
      'EasyCrmCase-Author' => easy_crm_case.author.login
    redmine_headers 'EasyCrmCase-Assignee' => easy_crm_case.assigned_to.login if easy_crm_case.assigned_to
    redmine_headers 'EasyCrmCase-ExternalAssignee' => easy_crm_case.external_assigned_to.login if easy_crm_case.external_assigned_to
    message_id journal
    references easy_crm_case

    @easy_crm_case = easy_crm_case
    @journal = journal
    @easy_crm_case_url = easy_crm_case_url(easy_crm_case, anchor: "change-#{journal.id}")

    if [easy_crm_case.assigned_to, easy_crm_case.external_assigned_to].include?(user)
      subject_key = 'mail.subject.my_easy_crm_case_edit'
    else
      subject_key = 'mail.subject.easy_crm_case_edit'
    end

    subject = l(subject_key,
      status: easy_crm_case.easy_crm_case_status.name,
      name: easy_crm_case.name,
      projectname: easy_crm_case.project.family_name(separator: ' > '))

    mail to: user, subject: subject
  end

end
