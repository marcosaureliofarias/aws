module EasyJob
  class TaskWrapper
    include Logging

    STATE_PENDING = 0
    STATE_RUNNING = 1
    STATE_FINISHED = 2

    MAX_DB_CONNECTION_ATTEMPTS = 100

    attr_reader :state, :duration, :current_user

    def initialize(task_class, args)
      @task_class = task_class
      @args = args
      @state = STATE_PENDING
      @task_caller = caller_locations

      @connection_attempt = 0
      @current_user = User.current
      @current_locale = I18n.locale
    end

    def job_id
      @job && @job.job_id
    end

    def self.job_name
      name
    end

    def job_name
      @task_class.job_name
    end

    def pending?
      @state == STATE_PENDING
    end

    def running?
      @state == STATE_RUNNING
    end

    def finished?
      @state == STATE_FINISHED
    end

    def perform(**options)
      @job = @task_class.new
      @job.job_options = options
      @job.job_id = SecureRandom.uuid

      Thread.current[:easy_job] = { id: @job.job_id }
      started_at = Time.now

      ensure_connection {
        ensure_redmine_env {
          begin
            log_info 'Job started'
            @state = STATE_RUNNING
            @job.perform(*@args)
          rescue => ex
            handle_error(@job, ex)
          ensure
            @state = STATE_FINISHED
            @duration = (Time.now - started_at).round(2)
            log_info "Job ended (in #{@duration}s)"
            ActiveSupport::Notifications.instrument('finished.easy_job', wrapper: self)
          end
        }
      }
    rescue => e
      # Perform method must end successfully.
      # Otherwise `all_done?` end on deadlock.
    ensure
      Thread.current[:easy_job] = nil
    end

    def ensure_connection
      ActiveRecord::Base.connection_pool.with_connection { yield }
    rescue ActiveRecord::ConnectionTimeoutError
      @connection_attempt += 1
      if @connection_attempt > MAX_DB_CONNECTION_ATTEMPTS
        log_error 'Max ConnectionTimeoutError'
        return
      else
        log_warn "ConnectionTimeoutError attempt=#{@connection_attempt}"
        retry
      end
    end

    def ensure_redmine_env
      orig_user = User.current
      orig_locale = I18n.locale
      User.current = @current_user
      I18n.locale = @current_locale
      yield
    ensure
      User.current = orig_user
      I18n.locale = orig_locale
    end

    # Other classes can prepend this method and handle error
    # See `EasyJob::ExceptionsNotifier`
    def handle_error(job, ex)
      job.handle_error(ex)
    end

    def inspect
      id = job_id.presence || 'not yet'
      %{#<EasyJob::TaskWrapper(#{@task_class}) id="#{id}">}
    end

  end
end
