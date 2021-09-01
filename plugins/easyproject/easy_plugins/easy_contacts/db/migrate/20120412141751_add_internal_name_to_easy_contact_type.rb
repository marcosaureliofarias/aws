# encoding: utf-8
class AddInternalNameToEasyContactType < ActiveRecord::Migration[4.2]
  def self.up
    EasyContactType.reset_column_information
    if c = EasyContactType.where(:type_name => 'Osoba').first
      c.internal_name = 'personal'
      c.save!
    end
    if d = EasyContactType.where({:type_name => 'Organizace'}).first
      d.internal_name = 'corporate'
      d.save!
    end
  end

  def self.down
  end
end
