module EasyHelpdesk
  module EasyIssuesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_render :set_easy_helpdesk_sla_due_date, :only => :new

        alias_method_chain :dependent_fields, :easy_helpdesk
        alias_method_chain :render_tab, :easy_helpdesk

        def set_easy_helpdesk_sla_due_date
          if @issue && sla = @issue.easy_helpdesk_project_sla_from_project
            @issue.easy_sla_data_recalculate(sla)
          end
        end

      end
    end

    module InstanceMethods

      def dependent_fields_with_easy_helpdesk
        dependent_fields_without_easy_helpdesk
        set_easy_helpdesk_sla_due_date
      end

      def render_tab_with_easy_helpdesk
        if params[:tab] == 'easy_sla_events'
          @query = EasySlaEventQuery.new
          @query.filters = {}
          @query.column_names = [:name, :occurence_time, :issue, :project, :user, :sla_response, :sla_resolve, :first_response, :sla_response_fulfilment, :sla_resolve_fulfilment, :issue_status]
          @query.add_additional_scope(issue_id: @issue.id)
          render partial: 'issues/tab_easy_sla_events'
        else
          render_tab_without_easy_helpdesk
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyIssuesController', 'EasyHelpdesk::EasyIssuesControllerPatch'
