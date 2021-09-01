class EpmAttendanceUserList < EasyPageModule

  def category_name
    @category_name ||= 'easy_attendances'
  end

  def permissions
    @permissions ||= [:view_easy_attendance_other_users]
  end

  def runtime_permissions(user)
    EasyAttendance.enabled?
  end

end
