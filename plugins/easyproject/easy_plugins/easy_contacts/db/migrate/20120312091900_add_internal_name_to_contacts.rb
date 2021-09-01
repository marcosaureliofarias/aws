# encoding: utf-8
class AddInternalNameToContacts < ActiveRecord::Migration[4.2]
  def self.up
    EasyContactCustomField.where(:name => 'Organizace').update_all(:internal_name => 'easy_contacts_organization', :non_deletable => true)
    EasyContactCustomField.where(:name => 'E-mail').update_all(:internal_name => 'easy_contacts_email', :non_deletable => true)
    EasyContactCustomField.where(:name => 'Telefon').update_all(:internal_name => 'easy_contacts_telephone', :non_deletable => true)
    EasyContactCustomField.where(:name => 'Ulice').update_all(:internal_name => 'easy_contacts_street', :non_deletable => true)
    EasyContactCustomField.where(:name => 'Město').update_all(:internal_name => 'easy_contacts_city', :non_deletable => true)
    EasyContactCustomField.where(:name => 'Kraj').update_all(:internal_name => 'easy_contacts_region', :non_deletable => true)
    EasyContactCustomField.where(:name => 'PSČ').update_all(:internal_name => 'easy_contacts_postal_code', :non_deletable => true)
    EasyContactCustomField.where(:name => 'Země').update_all(:internal_name => 'easy_contacts_country', :non_deletable => true)
  end

  def self.down
  end
end
