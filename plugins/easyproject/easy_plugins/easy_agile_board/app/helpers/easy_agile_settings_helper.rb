module EasyAgileSettingsHelper

  def easy_agile_settings_tabs
    tabs = []
    tabs << {name: 'scrum', label: l(:title_sprint_settings), partial: 'easy_agile_board/settings_form', no_js_link: true}
    tabs << {name: 'kanban', label: l(:title_kanban_settings), partial: 'easy_kanban/settings_form', no_js_link: true}
    tabs
  end

end
