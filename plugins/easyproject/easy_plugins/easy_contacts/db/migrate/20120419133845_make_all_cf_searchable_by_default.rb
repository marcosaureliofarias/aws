class MakeAllCfSearchableByDefault < ActiveRecord::Migration[4.2]
  def self.up
    EasyContactCustomField.all.each do |cf|
      cf.update_attribute(:searchable, true)
    end
  end

  def self.down
  end
end
