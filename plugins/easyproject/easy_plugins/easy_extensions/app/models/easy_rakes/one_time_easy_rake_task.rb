class OneTimeEasyRakeTask < EasyRakeTask

  def self.one_time_task
    OneTimeEasyRakeTask.first || OneTimeEasyRakeTask.create(:active => true, :settings => {}, :period => :minutes, :interval => 1, :next_run_at => Time.now.beginning_of_day, :builtin => 1)
  end

  def self.execute_task(task, my_logger = nil)
    started_at = Time.now
    log_info "--> Starting #{task.class.name}: #{task.caption} at #{started_at}", my_logger

    task.easy_rake_task_infos.status_planned.find_each(:batch_size => 1) do |current_info|
      execute_task_with_current_info(task, current_info, my_logger)
    end

    log_info "--> Finished #{task.class.name}: #{task.caption} in #{Time.now - started_at}", my_logger
  end

  def self.create_one_time_task(method_to_execute, options = {})
    one_time_task.create_one_time_task(method_to_execute, options)
  end

  def create_one_time_task(method_to_execute, options = {})
    easy_rake_task_infos.create(:status => EasyRakeTaskInfo::STATUS_PLANNED, :started_at => Time.now, :options => options, :method_to_execute => method_to_execute)
  end

  def is_one_time?
    true
  end

  def deletable?
    false
  end

  def execute
    return true if current_easy_rake_task_info.nil? || current_easy_rake_task_info.method_to_execute.blank?
    mte = "execute_#{current_easy_rake_task_info.method_to_execute.to_sym}"

    if respond_to?(mte)
      send(mte, current_easy_rake_task_info.options)
    else
      return "Method #{mte} doesn't exists!"
    end
  end

  # OneTimeEasyRakeTask.create_one_time_task('kuk', {:issue_id => 1234})
  def execute_kuk(options = {})
    # do somekind of magic
    true
  end

end
