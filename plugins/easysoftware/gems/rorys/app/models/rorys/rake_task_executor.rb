# frozen_string_literal: true

module Rorys
  class RakeTaskExecutor < ::EasyRakeTask

    def self.execution_disabled?
      Rorys.use_for_rake_task? && Rorys.sidekiq_available?
    end

    def self.create_record!
      return if !table_exists?

      find_or_create_by!({}) do |task|
        task.active = true
        task.settings = {}
        task.period = 'minutes'
        task.interval = 5
        task.builtin = true
        task.next_run_at = Time.now
      end
    end

    def execute
      tasks = Rorys::EnqueuedTask.where('start_at <= ?', Time.now)

      tasks.each do |task|
        log_info "    * Execute Rorys cron job `#{task.data['job_class']}`"
        begin
          task.data['job_class'].constantize.perform_now(*task.data['args'])
        # rescue => e
          # TODO: Log the error
        ensure
          cron = Fugit.parse_cron(task.executions)
          task.update_column(:start_at, cron.next_time.to_local_time)
        end
      end
      true
    end

  end
end
