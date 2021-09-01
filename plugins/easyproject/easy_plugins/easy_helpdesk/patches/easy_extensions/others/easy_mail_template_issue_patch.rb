module EasyHelpdesk
  module EasyMailTemplateIssuePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def self.get_mail_sender(issue, mailbox = nil)
          # If custom sender is allowed and it is not blank
          custom_sender = EasySetting.value('easy_helpdesk_allow_custom_sender') && EasySetting.value('easy_helpdesk_custom_sender', issue.project, false)
          return custom_sender if custom_sender.present?
          
          case EasySetting.value('easy_helpdesk_sender')
          when 'current_user'
            User.current.mail_with_name
          when 'mailbox_address'
            issue.easy_helpdesk_mailbox_username || mailbox.try(:sender_mail) || Setting.mail_from || User.current.mail
          else
            # also redmine_default
            Setting.mail_from
          end
        end

        def self.from_easy_helpdesk_mail_template(issue, easy_helpdesk_template_id)
          @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.find_by(id: easy_helpdesk_template_id)
          return nil if @easy_helpdesk_mail_template.nil?
          t = new
          mailbox = @easy_helpdesk_mail_template.mailboxes.first
          if mailbox
            t.mail_reply_to = mailbox.sender_mail.to_s.strip
          end

          journal = issue.journals.last

          t.mail_subject = issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.subject, journal, t)
          t.mail_body_html = issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.body_html, journal, t)
          t.mail_body_plain = Sanitize.clean(issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.body_plain, journal, t), output: :html)
          t.mail_sender = EasyExtensions::EasyMailTemplateIssue.get_mail_sender(issue, mailbox)
          t.mail_recepient = EasyExtensions::EasyMailTemplateIssue.get_external_emails_from_entity(issue)
          t.mail_cc = EasyExtensions::EasyMailTemplateIssue.get_easy_email_cc_from_entity(issue)
          t
        end
      end
    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'EasyExtensions::EasyMailTemplateIssue', 'EasyHelpdesk::EasyMailTemplateIssuePatch'
