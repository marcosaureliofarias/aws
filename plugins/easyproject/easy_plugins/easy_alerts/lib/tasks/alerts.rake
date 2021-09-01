namespace :alerts do

  desc <<-END_DESC
    Generate alert reports

    Example:
      bundle exec rake alerts:generate_reports RAILS_ENV=production

  END_DESC
  task :generate_reports  => :environment do
    puts "Generating alert reports..."
    Alert.generate_reports_all
  end

  desc <<-END_DESC
    Delete all old not sent reports

    Example:
      bundle exec rake alerts:delete_all_not_sent_reports RAILS_ENV=production

  END_DESC
  task :delete_all_not_sent_reports => :environment do
    puts "Delete all not sent reports..."
    AlertReport.delete_all_not_sent_reports
  end

  desc <<-END_DESC
    Send reports

    Example:
      bundle exec rake alerts:send_reports RAILS_ENV=production

  END_DESC
  task :send_reports => :environment do
    puts "Sending alert reports..."
    AlertMailer.send_not_emailed_reports
  end

  desc <<-END_DESC
    Purge old reports

    Example:
      bundle exec rake alerts:purge_reports RAILS_ENV=production

  END_DESC
  task :purge_reports => :environment do
    puts "Purging alert reports..."
    AlertReport.purge_all(31)
  end

  desc <<-END_DESC
    Do daily tasks at once: Generate, send new alert reports, after that it purge the old ones

    Example:
      bundle exec rake alerts:daily_maintenance RAILS_ENV=production

  END_DESC
  task :daily_maintenance => [
    :generate_reports, #1
    :delete_all_not_sent_reports, #2
    :send_reports,     #3
    :purge_reports]    #4

end
