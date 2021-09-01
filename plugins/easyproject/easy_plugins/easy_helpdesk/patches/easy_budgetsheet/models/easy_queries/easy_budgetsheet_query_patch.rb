module EasyHelpdesk
  module EasyBudgetSheetQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :available_filters, :easy_helpdesk

        def sql_for_is_under_helpdesk_field(field, operator, v)
          operator = v.first == self.class.connection.quoted_true ? "=" : "!"
          te = TimeEntry.joins(:issue, :easy_helpdesk_project).
            where(:issues => {:tracker_id => EasyHelpdeskProject.trackers}).select("#{TimeEntry.table_name}.id").to_sql
          "#{TimeEntry.table_name}.id #{(operator == '=') ? '' : 'NOT '}IN (#{te})"
        end

      end
    end

    module InstanceMethods
      def available_filters_with_easy_helpdesk
        available_filters_without_easy_helpdesk
        add_available_filter('is_under_helpdesk', { :type => :boolean, :order => 1, :group => l(:easy_helpdesk_name) })
      end
    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyBudgetSheetQuery', 'EasyHelpdesk::EasyBudgetSheetQueryPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_budgetsheet) }

