class EasyRakeTask < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::SubclassFactory

  MAXIMUM_BLOCKING = 2.days

  belongs_to :project
  has_many :easy_rake_task_infos, :dependent => :destroy

  scope :active, lambda { where(active: true) }

  acts_as_attachable

  attr_accessor :current_easy_rake_task_info, :my_logger

  store :settings, coder: JSON

  safe_attributes 'active', 'settings', 'project_id'
  safe_attributes 'period', 'interval', 'next_run_at', :if => lambda { |task, user| user.admin? }

  def self.disabled_sti_class
    EasyRakeTaskDisabled
  end

  def self.available_periods
    ['monthly', 'daily', 'hourly', 'minutes']
  end

  def self.create_scope(force = false)
    scope = if EasySetting.where(name: 'move_easy_web_application').exists?
              EasyRakeTask.none
            else
              EasyRakeTask.active
            end

    if !force
      scope = scope.where(["#{EasyRakeTask.table_name}.next_run_at <= ? OR #{EasyRakeTask.table_name}.next_run_at IS NULL", Time.now])
      scope = scope.where(["NOT EXISTS(SELECT erti.id FROM #{EasyRakeTaskInfo.table_name} erti WHERE erti.easy_rake_task_id = #{EasyRakeTask.table_name}.id AND erti.status = ? AND erti.started_at >= ?)", EasyRakeTaskInfo::STATUS_RUNNING, Time.now - 6.hours])
    end

    scope
  end

  def self.get_scoped_tasks(scope)
    tasks = []

    scope.to_a.each do |task|
      next if task.maintained_by_active_job? && queue_adapter_present?
      next if task.in_disabled_plugin?
      next if task.is_one_time? && task.easy_rake_task_infos.status_planned.count == 0
      next if task.blocked?
      next if task.class.execution_disabled?

      tasks << task
    end

    tasks
  end

  def self.scheduled(force = false)
    scope = create_scope(force)

    get_scoped_tasks(scope)
  end

  def self.execute_classes(klasses, force = false)
    return if execution_disabled?

    scope = create_scope(force)
    scope = scope.where(type: klasses)

    tasks = get_scoped_tasks(scope)

    execute_tasks(tasks)
  end

  def self.execute_scheduled(force = false, my_logger = nil, use_easy_delay: false)
    return if execution_disabled?
    return 'Site is moving .... disabled' if EasySetting.where(name: 'move_easy_web_application').exists?

    log_info '********************', my_logger
    log_info "EasyRakeTask::execute_scheduled(force = #{force.to_s}) at #{Time.now}", my_logger
    log_info '', my_logger

    save_last_executed_time

    tasks = scheduled(force)

    execute_tasks(tasks, my_logger, use_easy_delay: use_easy_delay)

    EasyJob.wait_for_all
  end

  def self.execute_scheduled_in_threads(force = false, my_logger = nil)
    return if execution_disabled?

    execute_scheduled(force, my_logger, use_easy_delay: true)

    EasyJob.wait_for_all
  end

  def self.execute_tasks(tasks, my_logger = nil, use_easy_delay: false)
    return if execution_disabled?

    tasks.each do |task|
      task_klass = task.class

      if use_easy_delay
        task_klass = task_klass.easy_delay
      end

      task_klass.execute_task(task, my_logger)
    end
  end

  def self.execute_task(task, my_logger = nil)
    return if execution_disabled?
    return if task.nil?

    started_at = Time.now
    log_info "--> Starting #{task.class.name}: #{task.caption} at #{started_at}", my_logger

    current_info = task.easy_rake_task_infos.create(:status => EasyRakeTaskInfo::STATUS_PLANNED, :started_at => Time.now)

    execute_task_with_current_info(task, current_info, my_logger)


    task.update_columns(:next_run_at      => task.calculate_next_run, :last_duration => (Time.now - started_at).round,
                        :average_duration => task.easy_rake_task_infos.where(:status => EasyRakeTaskInfo::STATUS_ENDED_OK).average('finished_at - started_at').to_i)

    log_info "--> Finished #{task.class.name}: #{task.caption} in #{Time.now - started_at}", my_logger
  end

  def self.execute_task_with_current_info(task, current_info, my_logger = nil)
    return if execution_disabled?
    return if task.nil? || current_info.nil?

    task.current_easy_rake_task_info = current_info
    task.my_logger                   = my_logger
    task.current_easy_rake_task_info.update_columns(:status => EasyRakeTaskInfo::STATUS_RUNNING, :started_at => Time.now)

    begin
      status = EasyRakeTaskInfo::STATUS_ENDED_OK

      ret_status = task.execute

      if ret_status == true
        msg    = ''
        status = EasyRakeTaskInfo::STATUS_ENDED_OK
      elsif ret_status == false
        msg    = ''
        status = EasyRakeTaskInfo::STATUS_ENDED_FAILED
      elsif ret_status.is_a?(Array)
        if ret_status.first == true
          msg    = ret_status.second.to_s
          status = EasyRakeTaskInfo::STATUS_ENDED_OK
        else
          msg    = ret_status.second.to_s
          status = EasyRakeTaskInfo::STATUS_ENDED_FAILED
        end
      else
        msg    = ret_status.to_s
        msg    = msg.dup.force_encoding('ascii') if msg.respond_to?(:force_encoding)
        status = EasyRakeTaskInfo::STATUS_ENDED_OK
      end

      task.current_easy_rake_task_info.update_columns({ :status => status, :finished_at => Time.now, :note => msg })
    rescue StandardError => ex
      msg = Redmine::CodesetUtil.replace_invalid_utf8(ex.message.to_s.dup)

      begin
        task.current_easy_rake_task_info.update_columns({ :status => EasyRakeTaskInfo::STATUS_ENDED_FAILED, :finished_at => Time.now, :note => msg })
      rescue StandardError
        msg = msg.encode('US-ASCII', :invalid => :replace, :undef => :replace, :replace => '?').encode('UTF-8')
        task.current_easy_rake_task_info.update_columns({ :status => EasyRakeTaskInfo::STATUS_ENDED_FAILED, :finished_at => Time.now, :note => msg })
      end

      log_info "ERROR #{task.class.name}: #{task.caption} - #{msg} at #{Time.now}", my_logger
      log_info ex.backtrace.join("\n"), my_logger
    end
  end

  def self.easy_report_setting
    EasyReportSetting.where(:name => 'EasyRakeTask').first
  end

  def self.save_last_executed_time(time = nil)
    ers          = easy_report_setting || EasyReportSetting.create(:name => 'EasyRakeTask')
    ers.last_run = time || Time.now
    ers.save
    ers
  end

  def self.queue_adapter_present?
    !%i(inline async).include?(Rails.application.config.active_job.queue_adapter)
  end

  def self.log_info(msg = '', my_logger = nil)
    EasyExtensions.puts(msg.to_s)

    if EasyRakeTask.logger
      if msg.is_a?(Array)
        (my_logger || EasyRakeTask.logger).info(msg.join("\n"))
      else
        (my_logger || EasyRakeTask.logger).info(msg.to_s)
      end
    end
  end

  def log_info(msg = '')
    self.class.log_info(msg, my_logger)
  end

  def self.logger
    @@easy_rake_tasks_logger ||= Logger.new(File.join(Rails.root, 'log', 'easy_rake_tasks.log'))
  end

  # To override!
  def execute
    raise NotImplementedError
  end

  def info_detail_status_caption(status)
    'unknown'
  end

  def category_caption_key
    :label_others
  end

  def caption
    l(:"easy_rake_tasks.#{self.class.name.underscore}.caption", :default => l(:label_unknown_plugin))
  end

  def maintained_by_active_job?
    false
  end

  def executed_until?(time_to)
    return false if !active?

    next_run_at.nil? || next_run_at <= time_to
  end

  #  def first_executing_time
  #    return Time.now if next_run_at.nil?
  #
  #    [next_run_at, Time.now].max
  #  end

  def settings_view_path
    #"easy_rake_tasks/settings/#{self.class.name.underscore}"
  end

  def visible?
    User.current.admin?
  end

  def debug?
    EasyExtensions.debug_mode?
  end

  def blocked?
    blocked_at && (blocked_at + MAXIMUM_BLOCKING) > Time.now
  end

  def additional_task_info_view_path
    'common/empty'
  end

  def deletable?
    builtin == 0
  end

  def is_one_time?
    false
  end

  def in_disabled_plugin?
    Redmine::Plugin.disabled?(registered_in_plugin)
  end

  def attachments_visible?(user)
    (user = User.current)
    true # attachment workaround
  end

  def registered_in_plugin
    :easy_extensions
  end

  def calculate_next_run(last_time = nil)
    last_time ||= self.next_run_at || Time.now

    calculated_next_time = last_time + case self.period.to_sym
                                       when :monthly
                                         self.interval.months
                                       when :daily
                                         self.interval.days
                                       when :hourly
                                         self.interval.hours
                                       when :minutes
                                         self.interval.minutes
                                       else
                                         0
                                       end

    if calculated_next_time < Time.now
      # pro ondru :)
      # tmp

      calculated_next_time = case self.period.to_sym
                             when :monthly
                               Time.now + self.interval.months
                             when :daily
                               Time.now + self.interval.days
                             when :hourly
                               Time.now + self.interval.hours
                             when :minutes
                               Time.now + self.interval.minutes
                             else
                               0
                             end
    end

    return calculated_next_time
  end

  private

  def self.execution_disabled?
    false
  end

end

# class EasyRakeTaskJob
#   include SuckerPunch::Job
#
#   #workers (ActiveRecord::Base.connection_pool.size - 1)
#   workers 2
#
#   def perform(task, my_logger)
#     ActiveRecord::Base.connection_pool.with_connection do
#       task.class.execute_task(task, my_logger)
#     end
#   end
#
# end
