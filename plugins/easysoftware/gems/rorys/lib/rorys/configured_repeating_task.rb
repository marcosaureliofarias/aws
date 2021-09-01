# frozen_string_literal: true

module Rorys
  class ConfiguredRepeatingTask

    def initialize(job_class, cron)
      @job_class = job_class
      @cron = cron
    end

    def perform_now(*args)
      @job_class.new(*args).perform_now
    end

    def perform_later(*args)
      if !Rorys.queuing_environment?
        Rails.logger.info "[#{@job_class}] repeating skipped"
      elsif Rorys.sidekiq_available?
        enqueue_repeat_to_sidekiq(args)
      else
        enqueue_repeat_to_easy_rake_task(args)
      end
    end

    private

    def enqueue_repeat_to_sidekiq(args)
      Sidekiq::Cron::Job.create(
        name: "#{@job_class} - #{@cron.to_cron_s}",
        cron: @cron.to_cron_s,
        class: @job_class.name,
        args: args,
        active_job: true,
      )
    end

    def enqueue_repeat_to_easy_rake_task(args)
      Rorys::EnqueuedTask.create!(
        start_at: @cron.next_time.to_local_time,
        data: {
          job_class: @job_class.name,
          args: args,
        },
        executor: 'easy_rake_tasks',
        executions: @cron.to_cron_s,
      )
    end

  end
end
