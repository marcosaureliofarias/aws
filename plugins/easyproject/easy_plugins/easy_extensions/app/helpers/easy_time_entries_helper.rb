module EasyTimeEntriesHelper

  def _report_easy_time_entries_path(project, *args)
    if project
      report_project_easy_time_entries_path(project, *args)
    else
      report_easy_time_entries_path(*args)
    end
  end

end