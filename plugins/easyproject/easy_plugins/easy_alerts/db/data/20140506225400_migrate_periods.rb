class MigratePeriods < ActiveRecord::Migration[4.2]

  def self.up

    Alert.all.each do |alert|
      alert.period_options ||= {}
      alert.period_options['hours'] = alert.rule_settings[:time_check] if alert.rule_settings[:time_check]
      alert.period_options['hours'] = alert.rule_settings[:hours_time_check] if alert.rule_settings[:hours_time_check]
      alert.period_options['hours'] = alert.rule_settings[:period_to] if alert.rule_settings[:period_to]

      if alert.period_options['hours']
        alert.period_options['period'] = 'every_day'
        alert.period_options['time'] = 'defined'
      else
        alert.period_options['period'] = 'every_day'
        alert.period_options['time'] = 'cron'
      end
      alert.save
    end

  end

end