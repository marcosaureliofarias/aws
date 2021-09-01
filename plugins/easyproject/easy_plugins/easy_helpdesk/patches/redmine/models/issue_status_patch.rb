module EasyHelpdesk
  module IssueStatusPatch

    def self.included(base)
      # base.include(InstanceMethods)

      base.class_eval do
        has_many :easy_helpdesk_mail_templates
      end

    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'IssueStatus', 'EasyHelpdesk::IssueStatusPatch'
