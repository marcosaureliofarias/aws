require 'easy_extensions/easy_mail_template'

module EasyExtensions
  class EasyMailTemplateIssue < EasyExtensions::EasyMailTemplate

    def self.get_external_emails_from_entity(issue)
      issue.easy_email_to
    end

    def self.get_easy_email_cc_from_entity(issue)
      issue.easy_email_cc
    end

  end
end
