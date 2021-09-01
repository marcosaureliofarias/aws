# frozen_string_literal: true

require 'fugit'

module Rorys
  # Base class for ALL Rorys jobs
  # @note Currently working only in Easy ecosystem
  class Task < ::EasyActiveJob

    LOG_BLOCK_LENGTH = 120

    # Don't move logic into the `enqueue` because job
    # on Sidekiq::Cron is enqueued twice
    #   1. When the job is added into cron's pool
    #   2. When the job is ready for execution is added into Sidekiq pool
    #
    def self.repeat(repeating)
      cron = Fugit.parse_cron(repeating) || Fugit.parse_nat(repeating)

      if !cron
        raise ArgumentError, "Unknown repeating options '#{repeating}'"
      end

      Rorys::ConfiguredRepeatingTask.new(self, cron)
    end

    def log_info(message, &block)
      message = "[#{self.class}] [job_id=#{job_id}] [provider_job_id=#{provider_job_id}] #{message}"

      if block_given?
        message_start = "--- START #{message} ".ljust(LOG_BLOCK_LENGTH, '-')

        super(message_start)
        puts(message_start)

        start_at = Time.now
        yield
        duration = (Time.now - start_at)

        message_end = "--- END #{message} (#{duration.round(2)}s) ".ljust(LOG_BLOCK_LENGTH, '-')

        super(message_end)
        puts(message_end)
      else
        super(message)
        puts(message)
      end
    end

  end
end
