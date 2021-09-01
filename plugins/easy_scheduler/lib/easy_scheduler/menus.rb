Redmine::MenuManager.map :easy_servicebar_items do |menu|
  menu.push :easy_scheduler_toolbar,
            { controller: 'easy_scheduler_quick', action: 'show', is_toolbar: true },
            caption: '',
            html: {
              class: 'icon-calendar',
              data: { remote: true },
              id: 'easy_scheduler_toolbar_trigger',
              title: EasyExtensions::MenuManagerProc.new { I18n.t(:label_calendar) }
            },
            if: Proc.new { !Redmine::Plugin.installed?(:easy_project_com) }
end

