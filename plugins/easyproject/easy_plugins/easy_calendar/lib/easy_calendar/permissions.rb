Redmine::AccessControl.map do |map|
  map.easy_category :easy_calendar do |pmap|
    pmap.permission :view_easy_calendar, {
      easy_rooms: [:availability],
      easy_meetings: [:show, :accept, :decline, :new, :create, :edit, :update, :destroy],
      easy_calendar: [:index, :feed]
    }, read: true, global: true
    pmap.permission :view_all_meetings_detail, {}, read: true, global: true
    pmap.permission :edit_easy_calendar_layout, {easy_calendar: [:edit_page_layout]}, global: true
    pmap.permission :edit_meetings, {}, global: true
  end
end
