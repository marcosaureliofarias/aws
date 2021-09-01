class UpdateGlobalContacts < ActiveRecord::Migration[4.2]
  def self.up
    # select all global groups
    EasyContact.reset_column_information
    global_group_ids = EasyContactGroup.where(:entity_id => nil).pluck(:id)
    EasyContactGroup.transaction do
      EasyContactGroup.where(EasyContactGroup.arel_table[:entity_id].not_eq(nil)).all.each do |ecg|
        ecg.easy_contacts.each do |c|
          n = false
          global_group_ids.each do |i|
            n = c.group_ids.include?(i)
            break if n
          end
          next if n
          c.update_attribute(:is_global, false)
        end
      end
    end

  end

  def self.down
  end
end
