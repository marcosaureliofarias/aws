module EasyHelpdesk
  module EasyPrintableTemplatePagesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :easy_printable_template_page_create_replacable_tokens_from_entity_project, :easy_helpdesk

      end
    end

    module InstanceMethods

      def easy_printable_template_page_create_replacable_tokens_from_entity_project_with_easy_helpdesk(project)
        tokens = easy_printable_template_page_create_replacable_tokens_from_entity_project_without_easy_helpdesk(project)

        if project.easy_helpdesk_project
          tokens['hd_monthly_hours'] = project.easy_helpdesk_project.monthly_hours || ''
          tokens['hd_spent_time_last_month'] = project.easy_helpdesk_project.spent_time_last_month || ''
          tokens['hd_spent_time_current_month'] = project.easy_helpdesk_project.spent_time_current_month || ''
          tokens['hd_aggregated_hours'] = project.easy_helpdesk_project.aggregated_hours || ''
          tokens['hd_aggregated_hours_remaining'] = project.easy_helpdesk_project.aggregated_hours_remaining || ''
          tokens['hd_aggregated_from_last_period'] = project.easy_helpdesk_project.aggregated_from_last_period || ''
          tokens['hd_remaining_hours'] = project.easy_helpdesk_project.remaining_hours || ''
        end

        tokens
      end

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EasyPrintableTemplatePagesHelper', 'EasyHelpdesk::EasyPrintableTemplatePagesHelperPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_printable_templates)}
