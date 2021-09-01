begin
  require 'rspec/core/rake_task'

  namespace :rorys do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, _task_args|
      args = []
      args << '--require' << Ryspec::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = Rorys::Engine.root.join('spec/**/*_spec.rb')
    end

    desc 'Test env'
    task :test_queue do
      s = []
      s << "Its queuing_environment? => `#{Rorys.queuing_environment?}`"
      s << "Is rake_running? => `#{Rorys.rake_running?}`"
      s << "Is sidekiq_server? => `#{Rorys.sidekiq_server?}`"
      s << "Is rails_server? => `#{Rorys.rails_server?}`"

      puts s.join("\n")
    end
  end
rescue StandardError, LoadError
  # Ignore when `ryspec` gem missing
end
