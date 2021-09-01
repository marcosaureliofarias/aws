class RemoveNonDeletableMarkFromRegion < ActiveRecord::Migration[4.2]
  def self.up
    cf = EasyContactCustomField.where({:internal_name => 'easy_contacts_region'}).first
    if cf
      cf.non_deletable = false
      cf.save
    end
  end

  def self.down
    cf = EasyContactCustomField.where({:internal_name => 'easy_contacts_region'}).first
    if cf
      cf.non_deletable = true
      cf.save
    end
  end
end
