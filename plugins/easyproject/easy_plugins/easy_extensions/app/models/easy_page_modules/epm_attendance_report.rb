class EpmAttendanceReport < EasyPageModule
  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'easy_attendances'
  end

  def permissions
    @permissions ||= [:view_easy_attendances]
  end

  def runtime_permissions(user)
    EasyAttendance.enabled?
  end

end
