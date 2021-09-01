module EasyHelpdesk
  module ProjectsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_helpdesk_projects
        include EasyHelpdeskProjectsHelper

        alias_method_chain :settings, :easy_helpdesk

      end
    end

    module InstanceMethods
      def settings_with_easy_helpdesk
        @easy_helpdesk_project = @project.easy_helpdesk_project
        if @easy_helpdesk_project
          @easy_helpdesk_project.easy_helpdesk_auto_issue_closers.build if @easy_helpdesk_project.easy_helpdesk_auto_issue_closers.blank?
          @issue_statuses = IssueStatus.preload(:easy_helpdesk_mail_templates).sorted
        end
        settings_without_easy_helpdesk
      end
    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ProjectsController', 'EasyHelpdesk::ProjectsControllerPatch'
