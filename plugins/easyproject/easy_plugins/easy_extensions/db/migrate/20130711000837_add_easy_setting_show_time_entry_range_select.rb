class AddEasySettingShowTimeEntryRangeSelect < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create :name => 'show_time_entry_range_select', :value => false
  end

  def down
    EasySetting.where(:name => 'show_time_entry_range_select').destroy_all
  end
end
