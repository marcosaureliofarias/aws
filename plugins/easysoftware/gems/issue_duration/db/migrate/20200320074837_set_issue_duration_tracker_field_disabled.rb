class SetIssueDurationTrackerFieldDisabled < ActiveRecord::Migration[5.2]
  def up
    Tracker.all.each do |tracker|
      tracker.core_fields = tracker.core_fields - ['easy_duration']
      tracker.save(validate: false)
    end
  end

  def down
  end
end
