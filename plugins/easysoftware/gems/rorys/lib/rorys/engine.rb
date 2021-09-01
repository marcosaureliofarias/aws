# frozen_string_literal: true

require 'rys'

module Rorys
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'rorys'

    config.before_configuration do |app|
      # app.config.active_job.queue_adapter = :sidekiq

      require Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/lib/easy_extensions/easy_extensions.rb')

      if Rorys.sidekiq_available? && Rorys.use_for_rake_task?
        EasyExtensions.easy_rake_tasks_trigger = 'rorys'
      end
    end

    generators do
      Rys::Hook.register('rys.plugin_generator.after_generated') do |generator|
        initializers_dir = File.join(generator.destination_root, 'config/initializers')

        initializers = Dir.glob(File.join(initializers_dir, '*.rb'))
        initializers.map! {|f| File.basename(f) }
        initializers.map! do |f|
          if m = f.match(/^(\d+)/)
            m[1].to_i
          else
            0
          end
        end
        next_number = initializers.max + 1

        source = root.join('lib/generators/rorys/templates/initializer.rb')
        target = "config/initializers/#{next_number.to_s.rjust(2, '0')}_jobs.rb"

        generator.template source, target

        source = root.join('lib/generators/rorys/templates/my_job.rb')
        target = 'app/jobs/%namespaced_name%/my_job.rb'

        generator.template source, target
      end
    end

    initializer 'rorys.setup', before: :load_config_initializers do
      if Rorys.queuing_environment?
        # Every start server will trigger new repeating jobs
        begin
          Sidekiq::Cron::Job.destroy_all!
        rescue Redis::BaseError => _e
          # Missing redis configuration or redis itself
        end
        if Rorys.sidekiq_available?

          # EasyRakeTasks are executed by Sidekiq
          Rorys::QueueEasyRakeTasksJob.repeat('every 1 minutes').perform_later if Rorys.use_for_rake_task?

          # Repeating jobs are scheduled by Sidekiq::Cron
          # Jobs are executed by ActiveJob.adapter
        else
          # Repeating jobs are scheduled by EasyRakeTask
          # EasyRakeTasks is executed by rake
          # Jobs are executed by ActiveJob.adapter
        end

        if Rorys::EnqueuedTask.table_exists?
          Rorys::EnqueuedTask.delete_all
        end
      end
    end

    # Redmine plugins are loaded via script in config/initializers
    initializer 'rorys.load_schedule_files', after: :load_config_initializers do
      if Rorys.queuing_environment?
        files = []

        Redmine::Plugin.all(without_disabled: true).each do |plugin|
          files << File.join(plugin.directory, 'config/schedule.yml')
        end

        RysManagement.all(systemic: true) do |plugin|
          files << plugin.root.join('config/schedule.yml')
        end

        files.each do |file|
          next unless File.exist?(file)

          yaml = YAML.load_file(file)
          yaml.each do |_name, options|
            klass = options['class'].constantize

            if klass < Rorys.task
              klass.repeat(options['cron']).perform_later
            else
              Rails.logger.warn("Class #{klass} is not rorys task so cannot be repeated")
            end
          end
        end
      end
    end

    initializer 'rorys.setup_rake_executor' do
      if Redmine::Plugin.installed?(:easy_extensions)
        Rorys::RakeTaskExecutor.create_record!
      end
    end

  end
end
