module EasyHelpdesk
  module IssuesControllerPatch

    def self.included(base)

      base.class_eval do

        before_render :set_easy_helpdesk_sla_due_date, :only => :new

        def set_easy_helpdesk_sla_due_date
          if @issue && sla = @issue.easy_helpdesk_project_sla_from_project
            @issue.easy_sla_data_recalculate(sla)
          end
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyHelpdesk::IssuesControllerPatch'
