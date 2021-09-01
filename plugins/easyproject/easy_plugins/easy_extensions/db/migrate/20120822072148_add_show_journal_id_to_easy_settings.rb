class AddShowJournalIdToEasySettings < ActiveRecord::Migration[4.2]
  def change
    EasySetting.create(:name => 'show_journal_id', :value => false)
  end
end
