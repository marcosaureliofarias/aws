require File.join(__dir__, '../easy_extensions/easy_extensions')

namespace :easyproject do
  namespace :scheduler do

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:scheduler:run_tasks RAILS_ENV=production
      bundle exec rake easyproject:scheduler:run_tasks force=true RAILS_ENV=production
    END_DESC
    task :run_tasks do

      if EasyExtensions.easy_rake_tasks_trigger == 'rake'
        Rake::Task['environment'].invoke

        force = !!ENV.delete('force')
        EasyRakeTask.execute_scheduled(force)
      else
        puts "Task 'run_tasks' is maintaned by '#{EasyExtensions.easy_rake_tasks_trigger}"
      end

    end

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:scheduler:run_task id=5 RAILS_ENV=production
    END_DESC
    task :run_task => :environment do

      task = EasyRakeTask.find(ENV['id'])
      EasyRakeTask.execute_task task

    end

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:scheduler:run_threaded_tasks RAILS_ENV=production
    END_DESC
    task :run_threaded_tasks => :environment do

      ActiveSupport::Deprecation.warn("Task 'run_threaded_tasks' is deprecated and will be removed in the next version")

      force = !!ENV.delete('force')
      EasyRakeTask.execute_scheduled_in_threads(force)

    end

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:scheduler:run_scoped_tasks scope=EasyRakeTaskEasyHelpdeskReceiveMail,EasyRakeTaskEasyCrmReceiveMail RAILS_ENV=production
    END_DESC
    task :run_scoped_tasks => :environment do

      force   = !!ENV.delete('force')
      klasses = ENV.delete('scope').to_s.split(',').map(&:strip)

      EasyRakeTask.execute_classes(klasses, force)
    end

  end
end