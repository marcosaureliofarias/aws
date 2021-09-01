module EasyRakeTasksHelper

  def task_period_caption(task)
    l(:"easy_rake_tasks.periods.#{task.period}", :interval => task.interval)
  end

  def task_info_status(task_info)
    case task_info.status
    when EasyRakeTaskInfo::STATUS_RUNNING
      l(:'easy_rake_task_infos.status.running')
    when EasyRakeTaskInfo::STATUS_ENDED_OK
      l(:'easy_rake_task_infos.status.ended_ok')
    when EasyRakeTaskInfo::STATUS_ENDED_FAILED
      l(:'easy_rake_task_infos.status.ended_failed')
    end
  end

  def task_period_description(task)
    s         = ''
    last_info = @last_infos[task.id]

    s << '<span class="overdue">' if last_info && last_info.failed?
    if task.active?
      s << l(:field_next_run_at)
      s << ' '
      s << distance_of_time_in_words(Time.now, task.first_executing_time)
      s << ' - '
    end

    s << task_period_caption(task)
    s << '</span>' if last_info && last_info.failed?

    if last_info
      s << '<br />'
      s << l(:'easy_rake_tasks.views.last_action')
      s << ' '
      s << distance_of_time_in_words(last_info.started_at, Time.now)
    end

    s.html_safe
  end

  def easy_rake_tasks_tabs
    tabs = [
        { name: 'overview', partial: 'overview', label: :'easy_rake_tasks.views.heading_index', redirect_link: true, url: easy_rake_tasks_path(tab: 'overview') },
        { name: 'sidekiq', partial: 'sidekiq', label: :'easy_rake_tasks.views.sidekiq', redirect_link: true, url: easy_rake_tasks_path(tab: 'sidekiq') }
    ]
#    tabs.delete_at(0) if in_mobile_view?

    return tabs
  end

  def task_delete_confirmation(task)
    l(:text_are_you_sure)
  end

end
