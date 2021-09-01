module EasyHelpdesk
  module EasyExternalEmailsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :set_easy_extensions_easy_mail_template_issue, :easy_helpdesk

        private

        def set_easy_extensions_easy_helpdesk_mail_template_issue(easy_mail_template, issue, journal = nil)
          if params[:easy_helpdesk_mail_template]
            @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.where(:id => params[:easy_helpdesk_mail_template]).first
          else
            @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.find_from_issue(issue) || EasyHelpdeskMailTemplate.default
          end
          if journal && !issue.easy_helpdesk_mailbox_username
            unless params[:easy_helpdesk_mail_template]
              # @easy_helpdesk_mail_template = nil
              html = Setting.text_formatting == 'HTML'
              easy_mail_template.mail_body_html = (journal.notes || '') + (html ? '<br />' : "\n")
              easy_mail_template.mail_body_plain = Sanitize.clean(journal.notes || '', :output => :html) + "\n"
              output_note = true
            end
          end
          if @easy_helpdesk_mail_template
            mailbox = @easy_helpdesk_mail_template.mailboxes.first
            if mailbox
              easy_mail_template.mail_reply_to = mailbox.sender_mail.to_s.strip
            end
            easy_mail_template.mail_subject ||= issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.subject, journal, easy_mail_template)
            easy_mail_template.mail_body_html = issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.body_html, journal, easy_mail_template)
            easy_mail_template.mail_body_plain = Sanitize.clean(issue.easy_helpdesk_replace_tokens(@easy_helpdesk_mail_template.body_plain, journal, easy_mail_template), :output => :html)
          else
            easy_mail_template.mail_reply_to = issue.easy_helpdesk_mailbox_username || Setting.mail_from
            easy_mail_template.mail_subject ||= issue.subject

            if journal && !output_note
              html = Setting.text_formatting == 'HTML'
              easy_mail_template.mail_body_html = (journal.notes || '') + (html ? '<br />' : "\n") + (easy_mail_template.mail_body_html || '')
              easy_mail_template.mail_body_plain = Sanitize.clean(journal.notes || '', :output => :html) + "\n" + Sanitize.clean(easy_mail_template.mail_body_plain || '', :output => :html)
            end
          end

          easy_mail_template.mail_sender = EasyExtensions::EasyMailTemplateIssue.get_mail_sender(issue, mailbox)

          easy_mail_template.mail_body_html ||= ''
          easy_mail_template.mail_body_plain ||= ''

          unless @easy_helpdesk_mail_template
            if Setting.text_formatting == 'HTML'
              easy_mail_template.mail_body_html << '<blockquote>'
              easy_mail_template.mail_body_html << issue.description.to_s
              easy_mail_template.mail_body_html << '</blockquote>'
            else
              easy_mail_template.mail_body_html << "\n\n"
              easy_mail_template.mail_body_html << '----------------------------------------'
              easy_mail_template.mail_body_html << "\n"
              easy_mail_template.mail_body_html << issue.description.to_s
            end

            easy_mail_template.mail_body_plain << "\n\n"
            easy_mail_template.mail_body_plain << '----------------------------------------'
            easy_mail_template.mail_body_plain << "\n"
            easy_mail_template.mail_body_plain << Sanitize.clean(issue.description.to_s, :output => :html)
          end
        end # end set_easy_extensions_easy_helpdesk_mail_template_issue

      end
    end

    module InstanceMethods

      def set_easy_extensions_easy_mail_template_issue_with_easy_helpdesk(easy_mail_template, issue, journal = nil)
        if issue.maintained_by_easy_helpdesk?
          set_easy_extensions_easy_helpdesk_mail_template_issue(easy_mail_template, issue, journal)
        else
          # Project is not maintened by helpdesk
          set_easy_extensions_easy_mail_template_issue_without_easy_helpdesk(easy_mail_template, issue, journal)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyExternalEmailsController', 'EasyHelpdesk::EasyExternalEmailsControllerPatch'
