module EasyMoney
  module OneTimeEasyRakeTaskPatch
    def self.included(base)
      base.class_eval do
        def execute_update_projects_time_entry_expenses(options = {})
          project_ids = options[:project_ids]
          if project_ids.nil?
            EasyMoneyTimeEntryExpense.update_all_projects_time_entry_expenses(Project.non_templates.active.has_module(:easy_money).pluck(:id))
          else
            EasyMoneyTimeEntryExpense.update_all_projects_time_entry_expenses(project_ids)
          end
          true
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch( 'OneTimeEasyRakeTask', 'EasyMoney::OneTimeEasyRakeTaskPatch')
