module EasyMoney
  class Hooks < Redmine::Hook::ViewListener

    include EasyExtensions::EasyAttributeFormatter

    render_on :view_projects_copy, :partial => 'projects/copy_module_easy_money'
    render_on :view_project_mass_copy_select_actions, :partial => 'project_mass_copy/copy_easy_money_rates'
    render_on :view_issue_sidebar_issue_info_after_menu_more, :partial => 'issues/easy_money_issue_sidebar_issue_info_after_menu_more'
    render_on :view_easy_invoices_show_sidebar, :partial => 'easy_invoices/easy_money_sidebar'

    def controller_projects_copy_after_copy_successful(context={})
      if context[:params][:project] && context[:params][:project][:inherit_easy_money_settings].to_s.to_boolean
        context[:saved_projects].each do |project|
          project.inherit_easy_money_settings = true
          project.copy_easy_money_settings_from_parent
        end
      end
    end

    def controller_projects_create_after_save(context={})
      if context[:params][:project] && context[:params][:project][:inherit_easy_money_settings].to_s.to_boolean
        project = context[:project]
        project.inherit_easy_money_settings = true
        project.copy_easy_money_settings_from_parent
      end
    end

    def controller_templates_create_project_from_template(context={})
      if context[:params][:template] && context[:params][:template][:inherit_easy_money_settings].to_s.to_boolean
        context[:saved_projects].each do |project|
          project.inherit_easy_money_settings = true
          project.copy_easy_money_settings_from_parent
        end
      end
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_money' if enabled_modules && enabled_modules.include?('easy_money')
    end

    def helper_project_settings_tabs(context={})
      project = context[:project]
      context[:tabs] << {:name => 'easymoney', :url => {:controller => 'easy_money_settings', :action => 'project_settings', :project_id => project}, :label => :label_easy_money_settings, :redirect_link => true} if project.module_enabled?(:easy_money) && User.current.allowed_to?(:easy_money_settings, project)
    end

    def helper_timelog_render_api_time_entry(context={})
      if Redmine::Plugin.installed?(:easy_budgetsheet) && context[:controller].is_a?(BudgetsheetController)
        names = EasyMoneyRateType.rate_type_cache.map do |rate_type|
          [(rate_type.name + EasyMoneyTimeEntryExpense::API_SUFFIX).to_sym, (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name).to_sym]
        end
        context[:api].easy_currency(context[:time_entry].project.try(:easy_currency_code))
        names.each do |name, assoc|
          context[:api].__send__(name, context[:time_entry].send(assoc))
        end
      end
    end

    def model_project_after_copy_issues(context={})
      project = context[:project]
      new_project = context[:new_project]
      issues_map = context[:issues_map]
      return unless project.module_enabled?(:easy_money) && new_project.module_enabled?(:easy_money)

      project.issues.with_easy_money_entities.find_each(:batch_size => 50) do |issue|
        new_issue = issues_map[issue.id]
        new_issue.copy_easy_money(issue) if new_issue
      end
    end

    def model_project_after_copy_versions(context={})
      project = context[:project]
      new_project = context[:new_project]
      versions_map = context[:versions_map]
      return unless project.module_enabled?(:easy_money) && new_project.module_enabled?(:easy_money)

      project.versions.with_easy_money_entities.find_each(:batch_size => 50) do |version|
        new_version = versions_map[version.id]
        new_version.copy_easy_money(version) if new_version
      end
    end

    def model_project_copy_additionals(context={})
      project = context[:source_project]
      context[:to_be_copied] << 'easy_money' if project.module_enabled?('easy_money')
    end

    # toto funguje pouze, kdyz v administraci existuje projekt a vypneme a zapneme penize
    def model_project_enabled_module_changed(context={})
      project = context[:project]
      unless project.id.nil?
        EasyMoneyRatePriority.rate_priorities_by_project(nil).copy_to(project) if project.module_enabled?(:easy_money)
      end
    end

    # toto funguje pouze v pripade, ze dany projekt kopiruju
    def model_project_copy_before_save(context={})
      source_project = context[:source_project]
      destination_project = context[:destination_project]
      if source_project.module_enabled?(:easy_money)
        EasyMoneyRatePriority.where(project_id: destination_project.id).delete_all
        EasyMoneyRatePriority.rate_priorities_by_project(source_project).copy_to(destination_project)
      end
    end

    def view_project_budgetsheet_table_header(context={})
      s = ''
      context[:additional_project_head_columns] ||= []
      EasyMoneyRateType.rate_type_cache.each do |rate_type|
        s << '<th width="10%">' + l("easy_money_rate_type.#{rate_type.name}") + '</th>'
        context[:total_sum] << 0.0 unless context[:total_sum].nil?
        context[:additional_project_head_columns] << l("easy_money_rate_type.#{rate_type.name}")
      end
      return s
    end

    # def view_project_budgetsheet_table_row(context={})
    #   entry = context[:entry]
    #   s = ''
    #   context[:additional_project_body_columns] ||= []
    #   if entry.project.easy_money_settings && entry.project.easy_money_settings.show_rate?('all')
    #     EasyMoneyRateType.rate_type_cache.each_with_index do |rate_type, i|
    #       expense = entry.easy_money_time_entry_expenses.easy_money_time_entries_by_rate_type(rate_type.id)
    #       if expense.empty?
    #         s << '<td align="center"> N/A </td>'
    #         context[:total_sum][i] = 0.0 unless context[:total_sum].nil?
    #         context[:additional_project_body_columns] << 'N/A'
    #       else
    #         s << '<td align="center">' + format_easy_money_price(expense.first.price, entry.project) + '</td>'
    #         context[:total_sum][i] += expense.first.price unless context[:total_sum].nil?
    #         context[:additional_project_body_columns] << expense.first.price
    #       end
    #     end
    #   else
    #     expense = entry.easy_money_time_entry_expenses.easy_money_time_entries_by_rate_type(EasyMoneyRateType.rate_type_cache.first.try(:id))
    #     if expense.empty?
    #       s << '<td align="center"> N/A </td>'
    #       context[:total_sum][0] = 0.0 unless context[:total_sum].nil?
    #       context[:additional_project_body_columns] << 'N/A'
    #     else
    #       s << '<td align="center">' + format_easy_money_price(expense.first.price, entry.project) + '</td>'
    #       context[:total_sum][0] += expense.first.price unless context[:total_sum].nil?
    #       context[:additional_project_body_columns] << expense.first.price
    #     end
    #     s << '<td align="center"> N/A </td>'
    #     context[:total_sum][1] = 0.0
    #     context[:additional_project_body_columns] << 'N/A'
    #   end
    #
    #   return s
    # end

    def view_projects_form(context={})
      f = context[:form]
      project = context[:project]
      if project.safe_attribute?('inherit_easy_money_settings')
        content_tag(:p, f.check_box(:inherit_easy_money_settings), :class => 'inheritance-option')
      end
    end

    def controller_projects_new(context={})
      context[:project].inherit_easy_money_settings = true unless context[:params][:project]
    end

    def view_issues_show_journals_top(context={})
      issue, project = context[:issue], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_issues?
      context[:controller].send(:render_to_string, :partial => 'issues/view_issues_show_journals_top', :locals => context)
    end

    def view_easy_crm_cases_show_journals_top(context={})
      easy_crm_case, project = context[:easy_crm_case], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_easy_crm_cases?
      context[:controller].send(:render_to_string, :partial => 'easy_crm_cases/view_easy_crm_cases_show_journals_top', :locals => context)
    end

    def view_projects_roadmap_version_header_bottom(context={})
      version, project = context[:version], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_versions?
      context[:controller].send(:render_to_string, :partial => 'versions/projects_roadmap_version_header_bottom', :locals => context)
    end

    def view_versions_show_before_history(context={})
      version, project = context[:version], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_versions?
      context[:controller].send(:render_to_string, :partial => 'versions/versions_show_before_history', :locals => context)
    end

    def view_issue_sidebar_issue_info_after_menu_more(context={})
      issue = context[:issue]
      project = issue.project
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_issues?
      context[:controller].send(:render_to_string, :partial => 'issues/easy_money_issue_sidebar_issue_info_after_menu_more', :locals => context)
    end

    def view_easy_crm_case_sidebar_bottom(context={})
      easy_crm_case = context[:easy_crm_case]
      project = easy_crm_case.project
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_easy_crm_cases?
      context[:controller].send(:render_to_string, :partial => 'easy_crm_cases/easy_money_easy_crm_case_sidebar_bottom', :locals => context)
    end

    def view_templates_create_project_from_template(context={})
      if context[:template_params].nil? || context[:template_params][:default_settings]
        checked = true
      elsif context[:template_params].present?
        checked = context[:template_params][:inherit_easy_money_settings] == '1'
      end

      html = label_tag('template[inherit_easy_money_settings]', l(:field_inherit_easy_money_settings))
      html << check_box_tag('template[inherit_easy_money_settings]', '1', checked)
      content_tag(:p, html, :class => 'inheritance-option')
    end

    def view_easy_printable_templates_token_list_bottom(context={})
      return if context[:section] != :plugins
      context[:controller].send(:render_to_string, :partial => 'easy_printable_templates/easy_money_view_easy_printable_templates_token_list_bottom', :locals => context)
    end

    def easy_reports_contingency_table_data_source_add_fields(context={})
      data_source = context[:data_source]

      require_dependency 'easy_money_easy_reports_project_contingency_fields'

      data_source.add_fields(
        EasyReports::ContingencyFields::TimeEntryInternalRateField.new(data_source), EasyReports::ContingencyFields::TimeEntryExternalRateField.new(data_source),
        EasyReports::ContingencyFields::EasyMoneyOtherRevenueIdField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenueNameField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenuePrice1Field.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenuePrice2Field.new(data_source),
        EasyReports::ContingencyFields::EasyMoneyOtherExpenseIdField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpenseNameField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpensePrice1Field.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpensePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedHoursField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedPayrollExpenseField.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedExpenseIdField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpenseNameField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpensePrice1Field.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpensePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedRevenueIdField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenueNameField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenuePrice1Field.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenuePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectRecoveryField.new(data_source), EasyReports::ContingencyFields::ProjectTimeEntryAverageHourlyExpenseField.new(data_source), EasyReports::ContingencyFields::ProjectOtherProfitField.new(data_source)
      )

      EasyMoneyOtherRevenueCustomField.all.each do |custom_field|
        data_source.add_field(EasyReports::ContingencyFields::EasyMoneyOtherRevenueCustomFieldReports.new(data_source, custom_field))
      end

      EasyMoneyOtherExpenseCustomField.all.each do |custom_field|
        data_source.add_field(EasyReports::ContingencyFields::EasyMoneyOtherExpenseCustomFieldReports.new(data_source, custom_field))
      end
    end

    def easy_calculation_actions_bottom(context={})
      return unless context[:project] && context[:calculation]
      context[:controller].send(:render_to_string, :partial => 'easy_money_expected_revenues/save_as_expected_revenue', :locals => context)
    end

    def pdf_issue_before_journals(context={})
      issue = context[:issue]

      # Access rights
      return unless issue.project.module_enabled?(:easy_money) &&
          issue.project.easy_money_settings.use_easy_money_for_issues? &&
          User.current.allowed_to?(:view_easy_money, issue.project) &&
          issue.easy_money_visible?

      instance = context[:instance]
      pdf = context[:pdf]
      project = issue.project
      easy_money_settings = project.easy_money_settings

      issue_width = instance.class::ISSUE_WIDTH
      issue_height = instance.class::ISSUE_HEIGHT
      font_size = 9
      box_width = 80
      box_margin = 3
      box_gap = issue_width - 2*box_width
      max_box_y = 0
      header_padding_top = 2

      # Proc for rendering record in a table
      render_record = Proc.new do |label, value|
        value_width = pdf.get_string_width(value)
        base_x = pdf.GetX
        base_y = pdf.GetY
        pdf.SetX(base_x + box_margin) # little margin

        pdf.RDMCell(issue_width, issue_height, label)
        pdf.SetX(base_x + box_width - value_width)
        pdf.RDMCell(issue_width, issue_height, value)

        pdf.SetXY(base_x, base_y + issue_height)
      end

      # Keep originals coordinates for reset
      original_x = pdf.GetX
      original_y = pdf.GetY

      # Header
      pdf.Ln
      pdf.SetFontStyle('B', font_size)
      pdf.RDMCell(issue_width, issue_height, l(:label_easy_money), 'B')
      pdf.SetFontStyle('', font_size)
      pdf.SetY(original_y + issue_height*2 + header_padding_top)



      # Plan
      # -----------------------------------------------------------------------

      if easy_money_settings.show_expected?
        base_box_x = pdf.GetX
        base_box_y = pdf.GetY

        x = pdf.GetX
        y = pdf.GetY
        pdf.SetFontStyle('B', font_size)
        pdf.RDMCell(box_width, issue_height, l(:label_easy_money_expected_budget))
        pdf.SetXY(x, y + issue_height)
        pdf.SetFontStyle('', font_size)

        # Incomes
        if User.current.allowed_to?(:easy_money_show_expected_revenue, project) || User.current.allowed_to?(:easy_money_manage_expected_revenue, project)
          render_record.call(l(:button_easy_money_project_expected_revenues), format_easy_money_price(issue.easy_money.sum_expected_revenues, project, no_html: true))
        end

        # Wage expenses
        if project.self_and_descendants.active.has_module(:time_tracking).size > 0 && User.current.allowed_to?(:easy_money_show_expected_payroll_expense, project) || User.current.allowed_to?(:easy_money_manage_expected_payroll_expense, project)
          if easy_money_settings.expected_payroll_expense_type == 'amount'
            render_record.call(l(:label_easy_money_expected_payroll_expenses), format_easy_money_price(issue.easy_money.sum_expected_payroll_expenses, project, no_html: true))
          else
            render_record.call(l(:button_easy_money_project_time_entry_expenses), format_easy_money_price(issue.easy_money.sum_expected_payroll_expenses, project, no_html: true))
          end
        end

        # Expenses
        if User.current.allowed_to?(:easy_money_show_expected_expense, project) || User.current.allowed_to?(:easy_money_manage_expected_expense, project)
          render_record.call(l(:button_easy_money_project_expected_expenses), format_easy_money_price(issue.easy_money.sum_expected_expenses, project, no_html: true))
        end

        # Profit
        if User.current.allowed_to?(:easy_money_show_expected_profit, project)
          render_record.call(l(:label_easy_money_project_index_profit), format_easy_money_price(issue.easy_money.expected_profit, project, no_html: true))
        end

        # Planned hours
        if project.self_and_descendants.active.has_module(:time_tracking).size > 0 && (User.current.allowed_to?(:easy_money_show_expected_payroll_expense, project) || User.current.allowed_to?(:easy_money_manage_expected_payroll_expense, project))
          if easy_money_settings.expected_payroll_expense_type == 'hours'
            render_record.call(l(:label_easy_money_project_index_sum_hours), l(:label_easy_money_hour, hours: issue.easy_money.sum_expected_hours))
          elsif easy_money_settings.expected_payroll_expense_type == 'estimated_hours' || easy_money_settings.expected_payroll_expense_type == 'planned_hours_and_rate'
            render_record.call(l(:label_easy_money_project_index_estimated_hours), l(:label_easy_money_hour, hours: (issue.easy_money.sum_expected_hours || 0.0).round(2)))
          end
        end

        # Store Y for the end
        max_box_y = pdf.GetY if pdf.GetY > max_box_y

        # Change position for reality box
        pdf.SetXY(original_x + box_width + box_gap, base_box_y)
      end



      # Reality
      # -----------------------------------------------------------------------

      x = pdf.GetX
      y = pdf.GetY
      pdf.SetFontStyle('B', font_size)
      pdf.RDMCell(box_width, issue_height, l(:label_easy_money_real_budget))
      pdf.SetXY(x, y + issue_height)
      pdf.SetFontStyle('', font_size)

      # Incomes
      if User.current.allowed_to?(:easy_money_show_other_revenue, project) || User.current.allowed_to?(:easy_money_manage_other_revenue, project)
        render_record.call(l(:button_easy_money_project_other_revenues), format_easy_money_price(issue.easy_money.sum_other_revenues, project, no_html: true))
      end

      # Wage Expenses
      if project.self_and_descendants.active.has_module(:time_tracking).size > 0 && User.current.allowed_to?(:easy_money_show_time_entry_expenses, project)
        render_record.call(l(:button_easy_money_project_time_entry_expenses), format_easy_money_price(issue.easy_money.sum_time_entry_expenses, project, no_html: true))
      end

      # Expenses
      if User.current.allowed_to?(:easy_money_show_other_expense, project) || User.current.allowed_to?(:easy_money_manage_other_expense, project)
        render_record.call(l(:button_easy_money_project_other_expenses), format_easy_money_price(issue.easy_money.sum_other_expenses, project, no_html: true))
      end

      # Travel costs
      if User.current.allowed_to?(:easy_money_show_travel_cost, project) && project.easy_money_settings.use_travel_costs?
        render_record.call(l(:button_easy_money_project_travel_costs), format_easy_money_price(issue.easy_money.sum_travel_costs, project, no_html: true))
      end

      # Travel expenses
      if  User.current.allowed_to?(:easy_money_show_travel_expense, project) && project.easy_money_settings.use_travel_expenses?
        render_record.call(l(:button_easy_money_project_travel_expenses), format_easy_money_price(issue.easy_money.sum_travel_expenses, project, no_html: true))
      end

      # Profit
      if User.current.allowed_to?(:easy_money_show_other_profit, project)
        render_record.call(l(:label_easy_money_project_index_profit), format_easy_money_price(issue.easy_money.other_profit, project, no_html: true))
      end

      # Time worked
      if project.self_and_descendants.active.has_module(:time_tracking).size > 0
        render_record.call(l(:button_easy_money_project_time_entry_hours), l(:label_easy_money_hour, hours: issue.easy_money.sum_time_entry_hours.round(2)))
      end

      # Profit margin
      if (issue.easy_money.sum_other_expenses + issue.easy_money.sum_time_entry_expenses) > 0
        _value = (issue.easy_money.other_profit / (issue.easy_money.sum_other_expenses + issue.easy_money.sum_time_entry_expenses) * 100).round(2).to_s << " %"
        render_record.call(l(:label_easy_money_profit_margin), _value)
      end



      # Store Y for the end
      max_box_y = pdf.GetY if pdf.GetY > max_box_y

      # Reset for the rest
      # Boxes can have a different height
      pdf.SetXY(original_x, max_box_y)
      pdf.Ln
    end

    def easy_xml_data_import_importer_set_importable(context={})
      unless (easy_money_setttings_xml = context[:xml].xpath('//easy_xml_data/easy-money-settings/*')).blank?
        context[:importables] << EasyXmlData::EasyMoneySettingsImportable.new(:xml => easy_money_setttings_xml)
      end

      unless (easy_money_other_revenues_xml = context[:xml].xpath('//easy_xml_data/easy-money-other-revenues/*')).blank?
        context[:importables] << EasyXmlData::EasyMoneyOtherRevenueImportable.new(:xml => easy_money_other_revenues_xml)
      end

      unless (easy_money_other_expenses_xml = context[:xml].xpath('//easy_xml_data/easy-money-other-expenses/*')).blank?
        context[:importables] << EasyXmlData::EasyMoneyOtherExpenseImportable.new(:xml => easy_money_other_expenses_xml)
      end

      unless (easy_money_expected_revenues_xml = context[:xml].xpath('//easy_xml_data/easy-money-expected-revenues/*')).blank?
        context[:importables] << EasyXmlData::EasyMoneyExpectedRevenueImportable.new(:xml => easy_money_expected_revenues_xml)
      end

      unless (easy_money_expected_expenses_xml = context[:xml].xpath('//easy_xml_data/easy-money-expected-expenses/*')).blank?
        context[:importables] << EasyXmlData::EasyMoneyExpectedExpenseImportable.new(:xml => easy_money_expected_expenses_xml)
      end
    end

    def easy_xml_data_exporter_collect_entities(context={})
      @projects = context[:exporter].instance_variable_get('@projects')
      money_projects = @projects.inject(Hash.new {|hash, key| hash[key] = [] } ) do |mem,var|
        if var.module_enabled?(:easy_money)
          mem[:ids] << var.id
          [:other_revenues, :other_expenses, :expected_revenues, :expected_expenses].each do |e|
            mem[e].concat(Array(var.send(e)))
          end
        end
        mem
      end

      @easy_money_settings = EasyMoneySettings.where(:project_id => money_projects[:ids])
      @easy_money_other_revenues = money_projects[:other_revenues].uniq
      @easy_money_other_expenses = money_projects[:other_expenses].uniq
      @easy_money_expected_revenues = money_projects[:expected_revenues].uniq
      @easy_money_expected_expenses = money_projects[:expected_expenses].uniq
    end

    def easy_xml_data_exporter_build_xml(context={})
      @easy_money_settings.to_xml(:builder => context[:builder], :skip_instruct => true) unless @easy_money_settings.blank?
      @easy_money_other_revenues.to_xml(:builder => context[:builder], :skip_instruct => true, :except => [:easy_repeat_settings], :procs => [Proc.new{|options, record| options[:builder].tag!('easy-repeat-settings', record.easy_repeat_settings.to_yaml, :type => 'yaml')}]) unless @easy_money_other_revenues.blank?
      @easy_money_other_expenses.to_xml(:builder => context[:builder], :skip_instruct => true, :except => [:easy_repeat_settings], :procs => [Proc.new{|options, record| options[:builder].tag!('easy-repeat-settings', record.easy_repeat_settings.to_yaml, :type => 'yaml')}]) unless @easy_money_other_expenses.blank?
      @easy_money_expected_revenues.to_xml(:builder => context[:builder], :skip_instruct => true, :except => [:easy_repeat_settings], :procs => [Proc.new{|options, record| options[:builder].tag!('easy-repeat-settings', record.easy_repeat_settings.to_yaml, :type => 'yaml')}]) unless @easy_money_expected_revenues.blank?
      @easy_money_expected_expenses.to_xml(:builder => context[:builder], :skip_instruct => true, :except => [:easy_repeat_settings], :procs => [Proc.new{|options, record| options[:builder].tag!('easy-repeat-settings', record.easy_repeat_settings.to_yaml, :type => 'yaml')}]) unless @easy_money_expected_expenses.blank?
    end

    def easy_xml_data_exporter_project_preload_list(context={})
      context[:list].concat([:other_revenues, :expected_revenues, :other_expenses, :expected_expenses])
    end
  end
end
