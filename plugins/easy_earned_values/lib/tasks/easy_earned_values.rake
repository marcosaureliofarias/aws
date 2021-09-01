namespace :easy_earned_values do

  desc 'Calculate data for new day. If rake run between midnight and 6 AM data will be saved as yesterday.'
  task :calculate => :environment do
    now = Time.now

    if now.hour.in?(0..6)
      date = now.to_date.yesterday
    else
      date = now.to_date
    end

    earned_values = EasyEarnedValue.for_reloading

    puts "Calculating data for #{earned_values.count} earned values"
    earned_values.find_each(batch_size: 10).with_index do |earned_value, index|
      print "  #{index+1}. #{earned_value.name} (##{earned_value.id})"

      if earned_value.reload_constantly
        earned_value.reload_all
      elsif earned_value.data_initilized
        earned_value.reload_actual
      else
        earned_value.reload_all
      end

      puts ' ... DONE'
    end
  end

end
