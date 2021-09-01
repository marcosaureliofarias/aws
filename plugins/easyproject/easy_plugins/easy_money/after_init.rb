%w(concerns decorators services).each do |folder|
  ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app', folder)
end

EasyExtensions::PatchManager.register_easy_page_controller 'EasyMoneyController', 'EasyMoneyBaseItemsController', 'EasyMoneyProjectCachesController'
EasyExtensions::PatchManager.register_easy_page_helper 'EasyMoneyHelper', 'EntityAttributeHelper', 'CustomFieldsHelper'

require 'easy_money/acts_as_easy_money'
require 'easy_money/settings_resolver'
require_dependency 'easy_money/easy_money_base_model'
require_dependency 'easy_money/easy_money_rate_type_cache'
require_dependency 'easy_money/easy_entity_imports/easy_money_base_model_csv_import'

ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app/decorators')

EpmEasyMoneyProjectCacheQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyExpectedExpenseQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyExpectedRevenueQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyOtherExpenseQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyOtherRevenueQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyTravelExpenseQuery.register_to_all(:plugin => :easy_money)
EpmEasyMoneyTravelCostQuery.register_to_all(:plugin => :easy_money)

Dir.entries(File.dirname(__FILE__) + '/lib/easy_money/easy_lookups').each do |file|
  next unless file.end_with?('.rb')
  require_relative "./lib/easy_money/easy_lookups/#{file}"
end
EasyExtensions::EasyLookups::EasyLookup.map do |easy_lookup|
  easy_lookup.register 'EasyMoney::EasyLookups::EasyLookupEasyMoneyExpectedExpense'
  easy_lookup.register 'EasyMoney::EasyLookups::EasyLookupEasyMoneyExpectedRevenue'
  easy_lookup.register 'EasyMoney::EasyLookups::EasyLookupEasyMoneyOtherExpense'
  easy_lookup.register 'EasyMoney::EasyLookups::EasyLookupEasyMoneyOtherRevenue'
  easy_lookup.register 'EasyMoney::EasyLookups::EasyLookupEasyMoneyTravelExpense'
end

EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(:page_name => 'easy-money-projects-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmNoticeboard.first, 'top-left', HashWithIndifferentAccess.new(:text => '<h1>Projects Finances Overiew</h1>
<p><a class="easy-demo-tutor-youtube-link" href="https://www.youtube.com/watch?v=XfQ0vkm01VY"><img alt="" src="data:image/png;base64,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" style="border:0px solid black; float:left; height:79px; margin-bottom:0px; margin-left:20px; margin-right:20px; margin-top:0px; width:114px" /></a>Projects Budgets are a part of Finance Management Plugin Bundle.&nbsp;This is finance overview of your projects. This page is customizable and its main purpose is to show global and quick statement of projects finances.</p>
<p><span style="color:#FF8C00"><strong>Bellow it shows sample Profit &amp; Loss statement of realization projects</strong></span></p>'), 1)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_money/hooks'
  require 'easy_money/internals'
  require 'easy_money/proposer'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_money, {:controller => 'easy_money_settings', :action => 'index'}, :html => {:class => "icon icon-money"}, :if => Proc.new { User.current.admin? }, :before => :settings
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_money, {:controller => 'easy_money', :action => 'project_index'}, :param => :project_id, :caption => :label_easy_money, :if => Proc.new { |p| User.current.allowed_to?(:view_easy_money, p) || User.current.admin? }
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push(:easy_money, :easy_money_path, {
      :caption => :menu_easy_money,
      :if => Proc.new { User.current.allowed_to_globally?(:view_easy_money, {}) },
      :before => :others,
      :html => {:class => 'icon icon-money'}
    })
    menu.push(:easy_money_issues_budget, :easy_money_issues_budget_path, {
      parent: :easy_money,
      caption: :button_easy_money_issues_budget,
      if: Proc.new { User.current.allowed_to_globally?(:view_easy_money) },
      :html => {:class => 'icon icon-money-portfolio'}
    })
    if Redmine::Plugin.installed?(:easy_crm)
      menu.push(:easy_money_crm_cases_budget, :easy_money_crm_cases_budget_path, {
          parent: :easy_money,
          caption: :button_easy_money_crm_cases_budget,
          if: Proc.new { User.current.allowed_to_globally?(:view_easy_money) },
          :html => {:class => 'icon icon-money-portfolio'}
      })
    end
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_money, {:controller => 'easy_money_settings', :action => 'index'}, :html => {:menu_category => 'extensions', :class => "icon icon-money"}, :if => Proc.new { User.current.admin? }, :before => :settings
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_money do |pmap|

      pmap.permission :view_easy_money, {:easy_money => [:project_index, :index], :easy_money_project_caches => :index, easy_money_issues_budget: [:index, :project_index], easy_money_crm_cases_budget: [:index, :project_index]}, :read => true

      pmap.permission :easy_money_show_expected_revenue, {:easy_money_expected_revenues => [:index, :show]}, :read => true

      pmap.permission :easy_money_manage_expected_revenue, {
        :easy_money_expected_revenues => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update, :bulk_edit, :bulk_update, :bulk_delete]
      }

      pmap.permission :easy_money_show_expected_expense, {:easy_money_expected_expenses => [:index, :show]}, :read => true

      pmap.permission :easy_money_manage_expected_expense, {
        :easy_money_expected_expenses => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update, :bulk_edit, :bulk_update, :bulk_delete]
      }

      pmap.permission :easy_money_show_expected_payroll_expense, {
        :easy_money_expected_payroll_expenses => [:inline_edit],
        :easy_money_expected_hours => [:inline_edit]
      }, :read => true

      pmap.permission :easy_money_show_travel_cost, {:easy_money_travel_costs => [:index, :show]}, :read => true

      pmap.permission :easy_money_show_travel_expense, {:easy_money_travel_expenses => [:index, :show]}, :read => true

      pmap.permission :easy_money_manage_expected_payroll_expense, {
        :easy_money_expected_payroll_expenses => [:inline_edit, :inline_update, :inline_expected_payroll_expenses, :update],
        :easy_money_expected_hours => [:inline_edit, :inline_update],
      }

      pmap.permission :easy_money_show_expected_profit, {:easy_money => [:inline_expected_profit]}, :read => true

      pmap.permission :easy_money_show_other_revenue, {:easy_money_other_revenues => [:index, :show]}, :read => true

      pmap.permission :easy_money_manage_other_revenue, {
        :easy_money_other_revenues => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update, :bulk_edit, :bulk_update, :bulk_delete],
      }

      pmap.permission :easy_money_show_time_entry_expenses, {:easy_money_time_entry_expenses => [:index]}, :read => true

      pmap.permission :easy_money_show_other_expense, {:easy_money_other_expenses => [:index, :show]}, :read => true

      pmap.permission :easy_money_manage_other_expense, {
        :easy_money_other_expenses => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update, :bulk_edit, :bulk_update, :bulk_delete]
      }

      pmap.permission :easy_money_manage_travel_cost, {
        :easy_money_travel_costs => [:index, :show, :new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :bulk_delete]
      }

      pmap.permission :easy_money_manage_travel_expense, {
        :easy_money_travel_expenses => [:index, :show, :new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :bulk_delete]
      }

      pmap.permission :easy_money_show_other_profit, {:easy_money => [:inline_other_profit]}, :read => true

      pmap.permission :easy_money_settings, {
        :easy_money_settings => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :easy_money_rate_priorities],
        :easy_money_time_entry_expenses => [:update_project_time_entry_expenses, :update_all_projects_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses],
        :easy_money_rates => [:update_rates, :update_rates_to_projects, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users, :inline_update, :bulk_edit, :bulk_update, :projects_select, :projects_update],
        :easy_money_priorities => [:update_priorities_to_projects, :update_priorities_to_subprojects]
      }

      pmap.permission :easy_money_move, {:easy_money => :move}

    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyExpectedExpenseCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_expected_expense_custom_field}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyExpectedRevenueCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_expected_revenue_custom_field}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyOtherExpenseCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_other_expense_custom_field}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyOtherRevenueCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_other_revenue_custom_field}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyTravelCostCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_travel_cost_custom_field}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyMoneyTravelExpenseCustomField.name, :partial => 'custom_fields/index', :label => :tab_easy_money_travel_expense_custom_field}

  if Redmine::Plugin.installed?(:easy_budgetsheet)
    Redmine::AccessControl.map do |map|
      map.easy_category :easy_budgetsheet do |pmap|
        pmap.permission :easy_budgetsheet_view_internal_rates, {}, :read => true, :global => true
        pmap.permission :easy_budgetsheet_view_external_rates, {}, :read => true, :global => true
      end
    end
  end

  EasyExtensions::EntityRepeater.map do |mapper|
    mapper.register 'EasyMoneyExpectedExpense'
    mapper.register 'EasyMoneyExpectedRevenue'
    mapper.register 'EasyMoneyOtherRevenue'
    mapper.register 'EasyMoneyOtherExpense'
  end

  EasyQuery.map do |query|
    query.register 'EasyMoneyExpectedExpenseQuery'
    query.register 'EasyMoneyExpectedRevenueQuery'
    query.register 'EasyMoneyOtherExpenseQuery'
    query.register 'EasyMoneyOtherRevenueQuery'
    query.register 'EasyMoneyTravelCostQuery'
    query.register 'EasyMoneyTravelExpenseQuery'
    query.register 'EasyMoneyProjectCacheQuery'
    query.register 'EasyMoneyIssuesBudgetQuery'
    query.register 'EasyMoneyCrmCasesBudgetQuery' if Redmine::Plugin.installed?(:easy_crm)
  end

  # register classes in the easy currency to prevent problem with missing classes in the entities list.
  EasyEntityWithCurrency.register EasyMoneyExpectedRevenue,
                                  EasyMoneyExpectedExpense,
                                  EasyMoneyOtherRevenue,
                                  EasyMoneyOtherExpense,
                                  EasyMoneyTravelCost,
                                  EasyMoneyTravelExpense,
                                  EasyMoneyExpectedPayrollExpense,
                                  EasyMoneyTimeEntryExpense

  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyExpectedRevenueCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyExpectedExpenseCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyOtherRevenueCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyOtherExpenseCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyTravelCostCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyTravelExpenseCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyExpectedPayrollExpenseCsvImport'
  AdvancedImporter.config.available_import_entities << 'EasyEntityImports::EasyMoneyTimeEntryExpenseCsvImport'
end

if Redmine::Plugin.installed?(:easy_data_templates)
  EasyXmlData::Exporter.exportables.push(:easy_money)
  EasyXmlData::Exporter.exportable_labels.store(:easy_money, :label_easy_money)
end

Rails.application.configure do
  assets_dir = Redmine::Plugin.find(:easy_money).assets_directory
  config.assets.precompile << File.join(assets_dir, 'stylesheets', 'easy_datatables.css')
  config.assets.precompile << File.join(assets_dir, 'javascripts', 'easy_datatables.js')
end
