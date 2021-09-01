class AddMeetingToNotifiedEvents < EasyExtensions::EasyDataMigration

  def up
    # Before this, there was no chance to skip notification emails
    Setting.notified_events += ['meeting']
  end

  def down
    Setting.notified_events -= ['meeting']
  end

end
