class UpdateGroupsOpened < ActiveRecord::Migration[4.2]
  def self.up
    EasyTimeEntryBaseQuery.update_all(:groups_opened => false)
  end

  def self.down
  end
end
