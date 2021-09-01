class AddDisplayJournalDetailsToEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create!(:name => 'display_journal_details', :value => true)
  end

  def down
    EasySetting.where(:name => 'display_journal_details').destroy_all
  end
end
