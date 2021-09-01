module EasyHelpdesk
  class ProjectFinder

    def self.by_email(email_subject, from, to, mailbox_username = nil)
      ehp = EasyHelpdeskProject.find_by_keyword(email_subject) if email_subject
      ehp ||= EasyHelpdeskProject.find_by_from_and_to(from, to, mailbox_username)
      ehp
    end

  end
end
