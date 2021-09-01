class RemoveEasyLevelJournalDetails < ActiveRecord::Migration[4.2]
  def up
    JournalDetail.where(:property => 'attr', :prop_key => 'easy_level').destroy_all
  end

  def down
  end
end
