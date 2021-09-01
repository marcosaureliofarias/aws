EasyExtensions::PatchManager.register_easy_page_controller 'EasyAttendancesController'

ActiveSupport.on_load(:easyproject, yield: true) do

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push(:'easy_attendance.button_settings', :easy_attendance_settings_path, {
        :if => Proc.new { User.current.admin? },
        :html => { :menu_category => 'extensions', :class => 'icon icon-controls' },
        :caption => :'easy_attendance.button_settings'
      })
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push(:'easy_attendance.button_settings', :easy_attendance_settings_path, {
        :if => Proc.new { User.current.admin? },
        :html => { :class => 'icon icon-controls' },
        :caption => :'easy_attendance.button_settings',
        :after => :easy_pdf_themes
      })
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push(:easy_attendances, :easy_attendances_overview_path, {
        :caption => :'easy_attendance.label',
        :if => Proc.new {User.current.allowed_to_globally?(:view_easy_attendances, {})},
        :before => :personal_statement,
        :html => {:class => 'icon icon-time'}
      })
    menu.push(:easy_attendances_list, {:controller => 'easy_attendances', :tab => 'list'}, {
        :parent => :easy_attendances,
        :caption => :label_list,
        :if => Proc.new {User.current.allowed_to_globally?(:view_easy_attendances, {})},
      })
    menu.push(:easy_attendances_report, :report_easy_attendances_path, {
        :parent => :easy_attendances,
        :caption => :label_report,
        :if => Proc.new {User.current.allowed_to_globally?(:view_easy_attendances, {})},
      })
  end

  Redmine::MenuManager.map :user_profile do |menu|
    menu.push :easy_attendances, :user_profile_menu_item_easy_attendances_calendar,
      :caption => EasyExtensions::MenuManagerProc.new{I18n.t(:'easy_attendance.label').html_safe + '&nbsp;<i class=\'icon-arrow down\'></i>'.html_safe},#"#{EasyExtensions::MenuManagerProc.new{I18n.t(:'easy_attendance.label')}}&nbsp;<i class='icon-arrow down'></i>".html_safe,
      :html => {:class => 'icon icon-time'},
      :if => Proc.new {User.current.internal_client? && User.current.allowed_to_globally?(:view_easy_attendances, {})},
      :after => :time_entries
    menu.push :easy_attendances_calendar, :user_profile_menu_item_easy_attendances_calendar,
      :parent => :easy_attendances,
      :caption => :label_calendar,
      :html => {:class => 'icon icon-time'},
      :if => Proc.new {User.current.internal_client? && User.current.allowed_to_globally?(:view_easy_attendances, {})}
    menu.push :easy_attendances_list, :user_profile_menu_item_easy_attendances_list,
      :parent => :easy_attendances,
      :caption => :label_list,
      :html => {:class => 'icon icon-time'},
      :if => Proc.new {User.current.internal_client? && User.current.allowed_to_globally?(:view_easy_attendances, {})}
    menu.push :easy_attendances_report, :user_profile_menu_item_easy_attendances_report,
      :parent => :easy_attendances,
      :caption => :label_report,
      :html => {:class => 'icon icon-time'},
      :if => Proc.new {User.current.internal_client? && User.current.allowed_to_globally?(:view_easy_attendances, {})}
  end

end

RedmineExtensions::Reloader.to_prepare do

  EasyExtensions::EasyProjectSettings.easy_attendance_enabled = true
  EasyExtensions::EasyProjectSettings.disabled_features[:permissions].delete('easy_attendances')


  Redmine::Activity.map do |activity|
    activity.register :easy_attendances, {:default => false}
  end

end
