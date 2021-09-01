# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_timesheets, :easy_timesheets_path,
#     caption: :label_easy_timesheets,
#     if: ->(p) { User.current.allowed_to_globally?(:view_easy_timesheets, {}) || User.current.allowed_to_globally?(:view_own_easy_timesheets, {}) },
#     html: { class: 'icon icon-time-add' }
#   menu.push :new_easy_timesheet, :new_easy_timesheet_path,
#     parent: :easy_timesheets,
#     caption: :heading_easy_timesheets_new,
#     if: ->(p) { User.current.allowed_to_globally?(:edit_easy_timesheets, {}) || User.current.allowed_to_globally?(:edit_own_easy_timesheets, {}) }
#   menu.push :easy_timesheet_find_by_easy_query, { controller: 'easy_queries', action: 'find_by_easy_query', :type => 'EasyTimesheetQuery', :title => :button_easy_timesheet_by_easy_query },
#     parent: :easy_timesheets,
#     caption: :button_easy_timesheet_by_easy_query,
#     html: {:remote => true},
#     if: ->(p) { User.current.allowed_to_globally?(:view_easy_timesheets, {}) || User.current.allowed_to_globally?(:view_own_easy_timesheets, {}) }
# end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:easy_timesheets,{ :controller => 'easy_timesheets', :action => 'index', :set_filter => 0}, {
    :parent => :personal_statement,
    :label => :label_easy_timesheets,
    :if => Proc.new{User.current.allowed_to_globally?(:view_easy_timesheets, {})}
  })
end
