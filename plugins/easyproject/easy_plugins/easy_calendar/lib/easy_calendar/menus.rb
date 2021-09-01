Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :easy_rooms, :easy_rooms_path, {
    :caption => :label_room_plural,
    :html => {:class => 'icon icon-home'},
    :if => Proc.new{User.current.admin?}
  }
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :easy_calendar, :easy_calendar_path, {
    :after => :personal_statement,
    :caption => :'easy_pages.modules.easy_calendar',
    :html => {:class => 'icon icon-calendar'},
    :if => Proc.new{User.current.allowed_to_globally?(:view_easy_calendar, {})}
  }
  menu.push :easy_calendar_rooms_availability, :availability_easy_rooms_path, {
    :parent => :easy_calendar,
    :caption => :label_rooms_availability,
    :if => Proc.new{User.current.allowed_to_globally?(:view_easy_calendar, {})}
  }
  menu.push :easy_calendar_find_by_worker, {:controller => 'easy_calendar', :action => 'find_by_worker'}, {
    :parent => :easy_calendar,
    :caption => :button_easy_calendar_by_user,
    :html => {:remote => true},
    :if => Proc.new{User.current.allowed_to_globally?(:view_easy_calendar, {})}
  }
end
