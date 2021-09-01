class CreateDefaultClosedNoteSettings < ActiveRecord::Migration[4.2]

  def self.up
    EasySetting.create(:name => 'issue_private_note_as_default', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'issue_private_note_as_default').destroy_all
  end

end
