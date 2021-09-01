require 'easy_extensions/easy_mail_template'

module EasyCrm
  class EasyMailTemplateEasyCrmCase < EasyExtensions::EasyMailTemplate

    def self.get_external_emails_from_entity(easy_crm_case)
      easy_crm_case.email
    end

    def self.get_easy_email_cc_from_entity(easy_crm_case)
      easy_crm_case.email_cc
    end

  end
end
