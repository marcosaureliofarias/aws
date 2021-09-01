namespace :easyproject do
  desc <<-END_DESC
    EasyProject installer

    Example:
      bundle exec rake easyproject:install RAILS_ENV=production
  END_DESC

  task :install_with_environment => :environment do
    unless EasyProjectLoader.can_start?
      puts 'The Easy Project cannot start because the Redmine is not migrated!'
      puts 'Please run `bundle exec rake db:migrate RAILS_ENV=production`'
      puts 'and than `bundle exec rake easyproject:install RAILS_ENV=production`'
      exit 1
    end
    prefix = task.application.original_dir == Rails.root.to_s ? "" : "app:"

    puts "Invoking db:migrate..."
    Rake::Task["#{prefix}db:migrate"].reenable
    Rake::Task["#{prefix}db:migrate"].invoke
    puts "Invoking redmine:plugins:migrate..."
    Rake::Task["#{prefix}redmine:plugins:migrate"].reenable
    Rake::Task["#{prefix}redmine:plugins:migrate"].invoke
    puts "Invoking easyproject:service_tasks:data_migrate..."
    Rake::Task["#{prefix}easyproject:service_tasks:data_migrate"].reenable
    Rake::Task["#{prefix}easyproject:service_tasks:data_migrate"].invoke
    puts "Invoking easyproject:currency_update_tables..."
    Rake::Task["#{prefix}easyproject:currency_update_tables"].reenable
    Rake::Task["#{prefix}easyproject:currency_update_tables"].invoke
    puts "Invoking easyproject:service_tasks:clear_cache..."
    Rake::Task["#{prefix}easyproject:service_tasks:clear_cache"].reenable
    Rake::Task["#{prefix}easyproject:service_tasks:clear_cache"].invoke
    puts "Invoking easyproject:service_tasks:invoking_cache..."
    Rake::Task["#{prefix}easyproject:service_tasks:invoking_cache"].reenable
    Rake::Task["#{prefix}easyproject:service_tasks:invoking_cache"].invoke

    EasyExtensions.additional_installer_rake_tasks.each do |t|
      t = "#{prefix}#{t}"

      puts 'Invoking ' + t.to_s
      Rake::Task[t].reenable
      Rake::Task[t].invoke
    end

    puts 'Invoking EasyExtensions::AfterInstallScripts.execute...'
    EasyExtensions::AfterInstallScripts.execute

    if Rails.env.production?
      # puts 'Precompile assets...'
      # Rake::Task["#{prefix}assets:precompile"].invoke
    else
      Rake::Task["#{prefix}easy_vue:compile"].invoke
    end

    puts 'Done.'
  end

  task :install_without_environment do
    puts 'Invoking generate_secret_token...'
    prefix = task.application.original_dir == Rails.root.to_s ? "" : "app:"
    # Rake::Task['generate_secret_token'].reenable
    Rake::Task["#{prefix}generate_secret_token"].invoke
    puts 'Invoking patch initializers...'
    Rake::Task["#{prefix}easyproject:patch_initializers"].invoke
    puts 'Invoking clearing session...'
    Rake::Task["#{prefix}tmp:clear"].reenable # tmp:sessions:clear
    Rake::Task["#{prefix}tmp:clear"].invoke
  end

  task :install do
    prefix = task.application.original_dir == Rails.root.to_s ? "" : "app:"
    Rake::Task["#{prefix}easyproject:install_without_environment"].reenable
    Rake::Task["#{prefix}easyproject:install_without_environment"].invoke
    Rake::Task["#{prefix}easyproject:install_with_environment"].reenable
    Rake::Task["#{prefix}easyproject:install_with_environment"].invoke

    puts 'Done.'
  end

  task :instal => :install

end
