class EasyRakeTaskAlertDailyMaintenance < EasyRakeTask

  def execute
    EasyAlertMaintenanceJob.perform_now

    return true
  end

  def category_caption_key
    :label_alerts
  end

  def registered_in_plugin
    :easy_alerts
  end

  def maintained_by_active_job?
    false
  end

end
