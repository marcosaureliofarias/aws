module EasyCrmSettingsHelper

  def easy_crm_case_setting_tabs
    tabs = []
    tabs << {name: 'easy_crm_case_statuses', label: l(:heading_easy_crm_case_status_index), partial: 'easy_crm_settings/tabs/easy_crm_case_statuses', no_js_link: true}
    tabs << {name: 'easy_user_targets', label: l(:label_easy_user_target), partial: 'easy_crm_settings/tabs/easy_user_targets', no_js_link: true}
    tabs << {name: 'easy_crm_kanban_settings', action: 'index', label: l(:label_easy_crm_kanban_settings), partial: 'easy_crm_kanban/tab_settings', no_js_link: true}
    tabs << {name: 'others', :action => 'index', label: l(:label_others), partial: 'easy_crm_settings/tabs/others', no_js_link: true}
    tabs
  end

end
