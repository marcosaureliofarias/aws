module EasyHelpdesk
  module EasyExternalMailerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :easy_external_mail, :easy_helpdesk

      end
    end

    module InstanceMethods
      def easy_external_mail_with_easy_helpdesk(mail_template, entity, journal = nil, all_attachments = [])
        if entity.respond_to?(:maintained_by_easy_helpdesk?) && entity.maintained_by_easy_helpdesk?
          mail_template.email_header = entity.maintained_easy_helpdesk_project.email_header unless entity.maintained_easy_helpdesk_project.email_header.blank?
          mail_template.email_footer = entity.maintained_easy_helpdesk_project.email_footer unless entity.maintained_easy_helpdesk_project.email_footer.blank?
        end
        easy_external_mail_without_easy_helpdesk(mail_template, entity, journal, all_attachments)
      end

    end


  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyExternalMailer', 'EasyHelpdesk::EasyExternalMailerPatch'
