class EasyRakeTaskAttendanceActivityAccumulation < EasyRakeTask

  def execute
    EasyAttendanceActivityUserLimit.find_each(:batch_size => 1) do |limit|
      limit.save_accumulated_days
    end
    return true
  end

  def category_caption_key
    :label_easy_attendance_activity_rake_category
  end

  def settings_view_path

  end

  def registered_in_plugin
    :easy_extensions
  end

end
