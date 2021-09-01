Redmine::AccessControl.map do |map|
  map.project_module :easy_attendances do |pmap|
    pmap.permission :edit_easy_attendance_approval_for_inferiors, {:easy_attendances => [:approval_save, :approval]}, :global => true
  end
end
