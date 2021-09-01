begin
  require 'rspec/core/rake_task'

  namespace :easy_sso do
    desc 'Runs rspec tests'
    RSpec::Core::RakeTask.new(:spec) do |task, _task_args|
      args = []
      args << '--require' << Ryspec::Engine.root.join('spec/spec_helper')

      task.rspec_opts = args
      task.pattern = EasySso::Engine.root.join('spec/**/*_spec.rb')
    end

    desc 'Disable SSO'
    task :disable_sso => :environment do
      EasySetting.where(name: "selected_identity_provider_name").destroy_all
      puts 'SSO was disabled.'
    end
  end
rescue StandardError, LoadError
  # Ignore when `ryspec` gem missing
end
