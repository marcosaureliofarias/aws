class EasyActiveJob < ActiveJob::Base
  queue_as :default

  class ExpectedException < StandardError

    attr_reader :original_exception

    def initialize(original_exception = nil, msg = nil)
      original_exception, msg = nil, original_exception if original_exception.is_a?(String)
      @original_exception = original_exception if original_exception.present?

      a = []
      a << "#{original_exception.class.name}: #{original_exception.message}" if original_exception
      a << "#{self.class.name}: #{msg}" if msg

      super(a.join(', '))
    end

  end

  class RetryException < ExpectedException
  end

  class JobFailed < ExpectedException
  end

  class JobCanceled < ExpectedException
  end

  retry_on ::Net::OpenTimeout, wait: :exponentially_longer, attempts: 10
  retry_on ::Timeout::Error, wait: :exponentially_longer, attempts: 10
  retry_on ::ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on ::EasyActiveJob::RetryException, wait: :exponentially_longer, attempts: 10

  discard_on ::ActiveJob::DeserializationError
  discard_on ::EasyActiveJob::JobCanceled

  discard_on(::EasyActiveJob::JobFailed) do |job, exception|
    exc = exception.respond_to?(:original_exception) && exception.original_exception
    exc ||= exception

    job.log_exception(exc)
  end

  # rescue_from(StandardError) do |exception|
  #   log_exception(exception)
  # end

  # before_enqueue do |job|
  #   j = EasyActiveJobStatistic.find_or_initialize_by(name: job.class.name)
  #   j.update(planned_at: Time.now, started_at: nil, finished_at: nil, duration: 0)
  # end
  #
  # before_perform do |job|
  #   j = EasyActiveJobStatistic.find_or_initialize_by(name: job.class.name)
  #   j.update(started_at: Time.now)
  # end
  #
  # after_perform do |job|
  #   j = EasyActiveJobStatistic.find_or_initialize_by(name: job.class.name)
  #   j.update(finished_at: Time.now, duration: Time.now - (j.started_at || Time.now))
  # end

  def self.ensure_sidekiq_job(cron_expr, cron_job_name = nil, args = {})
    cron_job_name, args = nil, cron_job_name if cron_job_name.is_a?(Hash)

    delete_sidekiq_job(cron_job_name)
    create_sidekiq_job(cron_expr, cron_job_name, args)
  end

  def self.delete_sidekiq_job(cron_job_name = nil)
    Sidekiq::Cron::Job.destroy(cron_job_name || name) if redis_connected?
  end

  def self.create_sidekiq_job(cron_expr, cron_job_name = nil, args = {})
    ActiveSupport::Deprecation.warn "create_sidekiq_job is deprecated. Use Rorys::Task.repeat = Inherit your job from Rorys::Task. See Rorys doc. for more info"
    cron_job_name, args = nil, cron_job_name if cron_job_name.is_a?(Hash)

    Sidekiq::Cron::Job.create(name: cron_job_name || name, cron: cron_expr, class: name, args: args) if redis_connected?
  end

  def self.redis_connected?
    Rorys.sidekiq_available?
  end

  def in_disabled_plugin?
    Redmine::Plugin.disabled?(registered_in_plugin)
  end

  def registered_in_plugin
    :easy_extensions
  end

  def my_logger
    @my_logger ||= Logger.new(Rails.root.join('log', 'easy_active_job.log'))
  end

  def log_info(msg = '')
    my_logger.info msg.is_a?(Array) && msg.join("\n") || msg.to_s
  end

  def log_exception(exc)
    my_logger.error "#{exc.class.name}: #{exc.message}"
    my_logger.error exc.backtrace
    EasyExtensions::ExceptionsNotifier::Sender.new.notify_hoptoad(exc)
  end

  alias :log_error :log_exception

end
