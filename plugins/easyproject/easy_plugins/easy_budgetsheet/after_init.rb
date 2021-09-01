EpmEasyBudgetSheetQuery.register_to_all(plugin: :easy_budgetsheet)

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_budgetsheet/hooks'

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push(:easy_budgetsheet, :overview_budgetsheet_path, {
        :caption => :budgetsheet_top_menu,
        :if => proc { User.current.allowed_to_globally?(:view_budgetsheet) },
        :before => :others,
        :html => {:class => 'icon icon-bullet-list'}
      })
    menu.push(:easy_budgetsheet_find_by_worker, {:controller => 'budgetsheet', :action => 'find_by_worker'}, {
        :parent => :easy_budgetsheet,
        :caption => :button_easy_budgetsheet_by_user,
        :html => {:remote => true},
        :if => Proc.new{ User.current.allowed_to_globally?(:view_budgetsheet, {}) && User.current.allowed_to_globally_view_all_time_entries? }
      })
    menu.push(:easy_budgetsheet_find_by_easy_query, { controller: 'easy_queries', action: 'find_by_easy_query', :type => 'EasyBudgetSheetQuery', :title => :button_easy_budgetsheet_by_easy_query }, {
        :parent => :easy_budgetsheet,
        :caption => :button_easy_budgetsheet_by_easy_query,
        :html => {:remote => true},
        :if => Proc.new{User.current.allowed_to_globally?(:view_budgetsheet, {})}
      })
  end

  Redmine::AccessControl.map do |map|
    map.easy_category :easy_budgetsheet do |pmap|
      pmap.permission :view_budgetsheet, {:budgetsheet => [:index, :find_by_worker, :find_by_easy_query, :overview]}, :read => true, :global => true
    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  EasySetting.map.boolean_keys(:show_billable_things, :billable_things_default_state)

  EasyQuery.map do |query|
    query.register 'EasyBudgetSheetQuery'
  end

end

EasyExtensions::PatchManager.register_easy_page_controller 'BudgetsheetController'

EasyExtensions::AfterInstallScripts.add do
  require 'utils/easy_page'

  store = File.join(EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_budgetsheet/assets/xml_data_store')
  payroll_data_file = File.join(store, 'payroll_and_invoicing_sheet.zip')

  EasyUtils::EasyPage.import_dashboard(page_name: 'payroll-and-invoicing-sheet', data_file: payroll_data_file, version: 2)
end
