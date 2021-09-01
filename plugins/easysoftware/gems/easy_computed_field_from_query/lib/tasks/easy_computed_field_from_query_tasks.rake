begin
  require 'rspec/core/rake_task'

  namespace :easy_computed_field_from_query do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, _task_args|
      args = []
      args << '--require' << Ryspec::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = EasyComputedFieldFromQuery::Engine.root.join('spec/**/*_spec.rb')
    end
  end
rescue StandardError, LoadError
  # Ignore when `ryspec` gem missing
end
