if !Rails.env.production?
  require 'rspec/core/rake_task'

  namespace :easy_zapier do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, task_args|
      args = []
      args << '--require' << EasyCore::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = EasyZapier::Engine.root.join('spec/**/*_spec.rb')
    end
  end
end
