Redmine::AccessControl.map do |map|
  map.easy_category :easy_timesheets do |pmap|
    pmap.permission :view_easy_timesheets, {:easy_timesheets => [:index]}, :global => true, :read => true
    # pmap.permission :view_own_easy_timesheets, {:easy_timesheets => [:show, :index]}, :global => true, :read => true

    # pmap.permission :add_easy_timesheets, {:easy_timesheets => [:new, :create]}, :global => true
    # pmap.permission :add_own_easy_timesheets, {:easy_timesheets => [:new, :create]}, :global => true

    # pmap.permission :edit_easy_timesheets, {:easy_timesheets => [:edit, :update]}, :global => true
    # pmap.permission :edit_own_easy_timesheets, {:easy_timesheets => [:edit, :update]}, :global => true

    # pmap.permission :delete_easy_timesheets, {:easy_timesheets => [:destroy]}, :global => true
  end
end

Redmine::AccessControl.update_permission :log_time, {
  :easy_timesheets => [:new, :create, :edit, :update, :destroy, :monthly_new, :monthly_create]
}
Redmine::AccessControl.update_permission :edit_time_entries, {
  :easy_timesheets => [:edit, :update, :destroy]
}
Redmine::AccessControl.update_permission :edit_own_time_entries, {
 :easy_timesheets => [:edit, :update, :destroy]
}
Redmine::AccessControl.update_permission :view_time_entries, {
  :easy_timesheets => [:index, :show, :personal_show, :monthly_show]
}
Redmine::AccessControl.update_permission :timelog_can_easy_locking, {
  :easy_timesheets => [:resolve_lock, :monthly_resolve_lock]
}
Redmine::AccessControl.update_permission :timelog_can_easy_unlocking, {
  :easy_timesheets => [:resolve_lock, :monthly_resolve_lock]
}
