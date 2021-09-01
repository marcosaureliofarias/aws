class CreateEasyRakeTaskEasyMeetingNotifier < EasyExtensions::EasyDataMigration
  def up
    EasyRakeTaskEasyMeetingNotifier.create!(active: true, settings: {}, period: :daily, next_run_at: Time.now.end_of_day + 2.hour, interval: 1, builtin: 1)
  end

  def down
    EasyRakeTaskEasyMeetingNotifier.destroy_all
  end
end
