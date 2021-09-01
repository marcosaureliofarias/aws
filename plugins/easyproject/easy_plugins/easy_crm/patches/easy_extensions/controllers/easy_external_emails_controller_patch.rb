module EasyCrm
  module EasyExternalEmailsControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_crm
        include EasyCrmHelper

        def set_easy_crm_easy_mail_template_easy_crm_case(easy_mail_template, easy_crm_case, journal = nil)
          @easy_crm_case ||= easy_crm_case

          if params[:easy_crm_case_mail_template].nil?
            @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.find_all_for_easy_crm_case(easy_crm_case).where(:easy_crm_case_status_id => easy_crm_case.easy_crm_case_status_id).first
          elsif params[:easy_crm_case_mail_template] == ''
            @easy_crm_case_mail_template = nil
          else
            @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.where(:id => params[:easy_crm_case_mail_template]).first
          end

          if @easy_crm_case_mail_template
            easy_mail_template.mail_subject ||= easy_crm_case.replace_tokens(@easy_crm_case_mail_template.subject)
            easy_mail_template.mail_body_html ||= easy_crm_case.replace_tokens(@easy_crm_case_mail_template.body_html)
          end

          if journal
            @easy_crm_case_url = url_for(:controller => 'easy_crm_cases', :action => 'show', :id => easy_crm_case, :anchor => "change-#{journal.id}")

            easy_mail_template.entity_url = @easy_crm_case_url
            easy_mail_template.mail_subject ||= l(:'mail.subject.easy_crm_case_edit', :status => easy_crm_case.easy_crm_case_status.name, :name => easy_crm_case.name, :projectname => easy_crm_case.project.family_name(:separator => ' > '))
            easy_mail_template.mail_body_html ||= (journal.notes || '')# + '<br />' + render_to_string(:template => 'easy_crm_mailer/easy_crm_case_updated', :formats => [:html], :layout => false)
          else
            @easy_crm_case_url = url_for(:controller => 'easy_crm_cases', :action => 'show', :id => easy_crm_case)
            easy_mail_template.entity_url = @easy_crm_case_url

            easy_mail_template.mail_subject ||= l(:'mail.subject.easy_crm_case_add', :status => easy_crm_case.easy_crm_case_status.name, :name => easy_crm_case.name, :projectname => easy_crm_case.project.family_name(:separator => ' > '))
            #easy_mail_template.mail_body_html ||= render_to_string(:template => 'easy_crm_mailer/easy_crm_case_add', :formats => [:html], :layout => false)
          end

          #easy_mail_template.mail_reply_to = easy_crm_case.project (?? nil) issue.easy_helpdesk_mailbox_username || Setting.mail_from
          easy_mail_template.mail_replies_to = EasyRakeTaskEasyCrmReceiveMail.where(:project_id => @project.id).collect{|r| r.sender_mail}
          easy_mail_template.mail_reply_to ||= easy_mail_template.mail_replies_to.first || Setting.mail_from

          if Setting.text_formatting == 'HTML'
            easy_mail_template.mail_body_html ||= ''
            easy_mail_template.mail_body_html << '<blockquote>'
            easy_mail_template.mail_body_html << easy_crm_case.description.to_s
            easy_mail_template.mail_body_html << '</blockquote>'

            if @easy_crm_case_mail_template.nil? && !User.current.easy_mail_signature.blank?
              easy_mail_template.mail_body_html = easy_mail_template.mail_body_html + '<br />' + User.current.easy_mail_signature
            end
          end

          #          if easy_crm_case.respond_to?(:maintained_easy_helpdesk_project) && easy_crm_case.maintained_easy_helpdesk_project
          #            easy_mail_template.email_header = easy_crm_case.maintained_easy_helpdesk_project.email_header unless easy_crm_case.maintained_easy_helpdesk_project.email_header.blank?
          #            easy_mail_template.email_footer = easy_crm_case.maintained_easy_helpdesk_project.email_footer unless easy_crm_case.maintained_easy_helpdesk_project.email_footer.blank?
          #          end

          easy_mail_template
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyExternalEmailsController', 'EasyCrm::EasyExternalEmailsControllerPatch'
