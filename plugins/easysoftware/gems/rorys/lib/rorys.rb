# frozen_string_literal: true

require 'rys'

require 'rorys/version'
require 'rorys/engine'

module Rorys

  autoload :ConfiguredRepeatingTask, 'rorys/configured_repeating_task'

  configure do |c|
    c.systemic = true
  end

  def self.rails_server?
    # This will works only if run "rails server" (not useful for production)
    # defined?(Rails::Server)

    !defined?(Rails::Console) && !defined?(Rails::Generators)
  end

  # Memoize the result
  # If redis would start later, there will be inconsistency
  def self.sidekiq_available?
    return @sidekiq_available unless @sidekiq_available.nil?
    return false unless (queue_adapter = Rails.application.config.active_job.queue_adapter)

    @sidekiq_available = queue_adapter == :sidekiq && (!!Sidekiq.redis_info rescue false)
  end

  def self.sidekiq_server?
    Sidekiq.server? && sidekiq_available?
  end

  def self.rake_running?
    defined?(Rake) && Rake.respond_to?(:application)
  end

  # TODO: Maybe add `Rails.env.test?`
  def self.queuing_environment?
    return @queuing_environment if defined?(@queuing_environment)

    @queuing_environment = !rake_running? && !Sidekiq.server? && rails_server?
  end

  # Its currently an idea
  #   - we can dynamically change ancestor to support more adapters
  def self.task
    Rorys::Task
  end

  # Use Rorys for processing EasyRakeTasks
  # @note This switch allow use Rorys as scheduler of jobs only - without processing any EasyRakeTask
  def self.use_for_rake_task?
    false
  end

end
