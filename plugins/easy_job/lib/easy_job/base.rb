##
# EasyJob::Base
#
# Abstract class for Tasks
#
module EasyJob
  class Base
    include Logging

    class_attribute :queue_name, instance_writer: false

    self.queue_name = 'default'

    attr_accessor :job_id
    attr_accessor :job_options

    # Perform task as soon as possible.
    #
    # == Example:
    #
    #   # Run now
    #   MyJob.perform_async 1, 2, 3
    #
    def self.perform_async(*args)
      wrapper = TaskWrapper.new(self, args)
      queue = EasyJob.get_queue(queue_name)
      queue.post(wrapper, &:perform)
      wrapper
    end

    # Perform task after giver delay.
    #
    # == Parameters:
    # interval::
    #   number of seconds between task executions
    #
    # == Example:
    #
    #   # Run task after 5s delay
    #   MyJob.perform_in 1, 2, 3, interval: 5
    #
    def self.perform_in(*args, interval:)
      wrapper = TaskWrapper.new(self, args)
      queue = EasyJob.get_queue(queue_name)
      concurrent_job = Concurrent::ScheduledTask.execute(interval.to_f, args: wrapper, executor: queue.pool, &:perform)
      EasyJob.block_all_done_for(interval)
      wrapper
    end

    # Perform task on given interval. Return an `Array[TaskWrapper, TimerTask]`.
    #
    # == Parameters:
    # interval::
    #   number of seconds between task executions
    #
    # timeout::
    #   number of seconds a task can run before it is considered to have failed
    #   (default: 9_999)
    #
    # starts_at::
    #   time of first execution
    #   nil is equal to Time.now + interval (default)
    #
    # == Example:
    #
    #   # Run task every 5s, start 10s from now
    #   MyJob.perform_every 1, 2, 3, interval: 5, start_at: Time.now+10.seconds
    #
    def self.perform_every(*args, interval:, timeout: 9_999, start_at: nil)
      if start_at.is_a?(Time)
        start_at = start_at - Time.now
      end

      if !start_at.is_a?(Numeric) || start_at < 0
        raise ArgumentError, 'Start_at must be a Numeric or Time in future.'
      end

      wrapper = TaskWrapper.new(self, args)

      task = Concurrent::TimerTask.new{|t| wrapper.perform(timer_task: t) }
      task.execution_interval = interval
      task.timeout_interval = timeout
      task.execute_after(start_at)

      [wrapper, task]
    end

    # In production is task performed async. In other cases synced.
    #
    # == Example:
    #
    #   MyJob.perform_later 1, 2, 3
    #
    def self.perform_later(*args)
      if Rails.env.production?
        perform_async(*args)
      else
        perform_now(*args)
      end
    end

    # Task is performed now (synced).
    #
    # == Example:
    #
    #   # Run now
    #   MyJob.perform_now 1, 2, 3
    #
    def self.perform_now(*args)
      TaskWrapper.new(self, args).perform
    end

    def self.job_name
      name
    end

    def job_name
      self.class.job_name
    end

    def perform(*)
      raise NotImplementedError
    end

    def handle_error(ex)
      log_error ex.message
      ex.backtrace.each do |line|
        log_error line
      end
    end

  end
end

