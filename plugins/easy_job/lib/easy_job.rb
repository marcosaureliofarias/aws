require 'monitor'
require 'concurrent'
require 'securerandom'
require 'timeout'

module EasyJob
  autoload :Base,           'easy_job/base'
  autoload :Task,           'easy_job/task'
  autoload :DelayTask,      'easy_job/delay_task'
  autoload :DelayTaskProxy, 'easy_job/delay_task'
  autoload :MailerTask,     'easy_job/mailer_task'
  autoload :TaskWrapper,    'easy_job/task_wrapper'
  autoload :Logger,         'easy_job/logger'
  autoload :Queue,          'easy_job/queue'
  autoload :Logging,        'easy_job/logging'
  autoload :SharedMutex,    'easy_job/shared_mutex'

  # Set to default
  @@queues = nil
  @@monitor = Monitor.new

  def self.synchronize(&block)
    @@monitor.synchronize { yield }
  end

  def self.get_queue(name)
    synchronize do
      @@queues ||= Concurrent::Map.new
      @@queues.fetch_or_store(name) { EasyJob::Queue.new(name) }
    end
  end

  # Block `all_done?` method for `interval` seconds.
  # Method `all_done?` is checking `scheduled_task_count`
  # but `ScheduledTask` is added to executor queue after delay time.
  def self.block_all_done_for(interval)
    synchronize do
      @@block_all_done_until ||= Time.now

      new_time = Time.now + interval.to_f
      if @@block_all_done_until < new_time
        @@block_all_done_until = new_time
      end
    end
  end

  # One time, non-blocking.
  def self.all_done?
    synchronize do
      return true if @@queues.nil?

      @@block_all_done_until ||= Time.now
      if @@block_all_done_until > Time.now
        false
      else
        @@queues.values.map(&:all_done?).all?
      end
    end
  end

  def self.timeout_error
    synchronize do
      return true if @@queues.nil?

      logger.error "Timeout! active queues are: #{@@queues.values.map{ |v| v.name }.join(", ")}"
    end
  end

  # Blocking passive waiting.
  def self.wait_for_all(wait_delay: 5)
    begin
      Timeout::timeout(3600) {
        loop {
          if all_done?
            return
          else
            sleep wait_delay
          end
        }
      }
    rescue Timeout::Error
      timeout_error
    end
  end

  def self.logger
    synchronize do
      @@loger ||= Logger.new(Rails.root.join('log', 'easy_jobs.log'))
    end
  end

end

# Ruby
require 'easy_job/ext/object'

# Rails
require 'easy_job/rails/dependencies_patch'
require 'easy_job/rails/message_delivery_patch'

if Rails.version < '5'
  require 'easy_job/rails/easy_job_adapter'
end

# Concurrent
require 'easy_job/concurrent/timer_task'

# Others
require 'easy_job/others/mail_with_globalid'
