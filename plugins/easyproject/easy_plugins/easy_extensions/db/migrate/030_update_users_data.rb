class UpdateUsersData < ActiveRecord::Migration[4.2]
  def self.up
    # User.all.each {|i| i.update_column(:cached_group_names, i.groups.collect(&:name).sort.join(', '))}
  end

  def self.down
  end
end
