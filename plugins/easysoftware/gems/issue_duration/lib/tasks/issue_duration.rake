begin
  require 'rspec/core/rake_task'

  namespace :issue_duration do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, task_args|
      args = []
      args << '--require' << Ryspec::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = IssueDuration::Engine.root.join('spec/**/*_spec.rb')
    end
  end
rescue StandardError, LoadError
  # Ignore when `ryspec` gem missing
end
