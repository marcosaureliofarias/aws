module EasyMoneySettingsHelper

  def easy_money_settings_tabs
    [
      {:name => 'EasyMoneyRatePriority', :partial => 'easy_money_rate_priorities/default_priorities', :label => :tab_easy_money_rate_priorities, :no_js_link => true},
      {:name => 'EasyMoneyRateRole', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_role, :entity_type => 'Role', :no_js_link => true},
      {:name => 'EasyMoneyRateTimeEntryActivity', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_time_entry_activity, :entity_type => 'TimeEntryActivity', :no_js_link => true},
      {:name => 'EasyMoneyRateUser', :partial => 'easy_money_rates/user_rates', :label => :tab_easy_money_rate_user, :no_js_link => true},
      {:name => 'EasyMoneyOtherSettings', :partial => 'easy_money_settings/other_settings', :label => :tab_easy_money_other_settings, :no_js_link => true}
    ]
  end

  def easy_money_project_settings_tabs(project)
    [
      {:name => 'EasyMoneyRatePriority', :partial => 'easy_money_rate_priorities/default_priorities', :label => :tab_easy_money_rate_priorities, :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateRole', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_role, :entity_type => 'Role', :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateTimeEntryActivity', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_time_entry_activity, :entity_type => 'TimeEntryActivity', :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateUser', :partial => 'easy_money_rates/user_rates', :label => :tab_easy_money_rate_user, :project => project, :no_js_link => true},
      {:name => 'EasyMoneyOtherSettings', :partial => 'easy_money_settings/other_settings', :label => :tab_easy_money_other_settings, :project => project, :no_js_link => true}
    ]
  end

  def render_setting_with_easy_currency(settings_resolver, setting_name, easy_currency_options, options = {})
    default_easy_currency_code = settings_resolver.currency_easy_currency_code
    easy_money_rate = EasyMoneyRate.find_rate_for_setting(setting_name, settings_resolver.project.try(:id))
    unit_rate = easy_money_rate.try(:unit_rate) || 0
    easy_currency_code = easy_money_rate.try(:easy_currency_code) || default_easy_currency_code

    html_options = {}
    if options[:invisible]
      html_options[:style] = 'display:none'
    end

    content_tag(:p, html_options) do
      concat label_tag("settings_#{setting_name}", options[:label] || l("label_easy_money_other_settings_#{setting_name}"))
      concat text_field_tag("settings[#{setting_name}][value]", unit_rate, size: 5)
      if easy_currency_options.any?
        concat select_tag("settings[#{setting_name}][easy_currency_code]", options_for_select(easy_currency_options, easy_currency_code), style: 'width: auto;')
      end

      if easy_money_rate && easy_money_rate.easy_currency_code != default_easy_currency_code && EasyCurrency[default_easy_currency_code]
        concat " (#{format_easy_money_price easy_money_rate.unit_rate(default_easy_currency_code), settings_resolver.project, default_easy_currency_code})".html_safe
      end
    end
  end

end
