# encoding: utf-8
class ModificationsEasyContacts2 < ActiveRecord::Migration[4.2]
  def self.up
    EasyContactType.reset_column_information
    if a = EasyContactType.where({:type_name => 'Osobní'}).first
      a.update_attributes(:type_name => 'Osoba', :internal_name => 'personal')
    elsif c = EasyContactType.where({:type_name => 'Osoba'}).first
      c.update_attributes(:internal_name => 'personal')
    else
      say 'WARNING !!! Rename "Osobní" easy contact type and add internal_name was failed !!!'
    end
    if b =  EasyContactType.where({:type_name => 'Firemní'}).first
      b.update_attributes(:type_name => 'Organizace', :internal_name => 'corporate')
    elsif d = EasyContactType.where({:type_name => 'Organizace'}).first
      d.update_attributes(:internal_name => 'corporate')
    else
      say 'WARNING !!! Rename "Firemní" easy contact type and add internal_name was failed !!!'
    end
    # select custom fields
    f = EasyContactCustomField.find_by_name('Jméno')
    l = EasyContactCustomField.find_by_name('Příjmení')
    say_with_time 'Transfer cf name and surname to new columns...' do

      EasyContact.all.each do |c|
        unless c.update_attributes(:firstname => c.custom_value_for(f).value, :lastname => c.custom_value_for(l).value)
          c.update_attributes(:firstname => c.contact_name)
        end
      end if f && l

    end

    say 'Destroy custom field "Jméno" and "Přijmení"'
    f.destroy if f
    l.destroy if l


  end

  def self.down
  end
end
