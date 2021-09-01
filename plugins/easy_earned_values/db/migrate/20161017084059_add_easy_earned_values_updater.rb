class AddEasyEarnedValuesUpdater < ActiveRecord::Migration[4.2]

  def up
    return unless rake_available?

    updater = EasyEarnedValuesUpdater.new(
      active: true,
      settings: {},
      period: 'daily',
      interval: 1
    )
    updater.next_run_at = Time.now.end_of_day
    updater.builtin = 1
    updater.save!
  end

  def down
    return unless rake_available?

    EasyEarnedValuesUpdater.destroy_all
  end

  def rake_available?
    # Autload path is registered in after_init
    if Redmine::Plugin.installed?(:easy_extensions)
      require_dependency 'easy_rake_tasks/easy_earned_values_updater'
      return true
    else
      return false
    end
  end

end
