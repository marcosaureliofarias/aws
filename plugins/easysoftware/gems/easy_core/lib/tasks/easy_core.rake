if Rails.env.test?
  require 'rspec/core/rake_task'

  namespace :easy_core do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, task_args|
      args = []
      args << '--require' << EasyCore::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = EasyCore::Engine.root.join('spec/**/*_spec.rb')
    end

    namespace :spec do
      desc 'Runs all ryses rspec tests'
      RSpec::Core::RakeTask.new(:all) do |task, task_args|
        args = []
        args << '--require' << Ryspec::Engine.root.join('spec/spec_helper')

        patterns = []
        Rys::PluginsManagement.all do |plugin|
          patterns << plugin.root.join('spec/**/*_spec.rb')
        end

        task.rspec_opts = args
        task.pattern = patterns.join(',')
      end
    end
  end
end
