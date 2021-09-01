# encoding: utf-8
class AddPredefCustomField < ActiveRecord::Migration[4.2]
  def self.up
    new_custom_fields = Array.new
    new_custom_fields << {:name => 'Titul', :attributes => {:field_format => 'string', :is_filter => false, :is_primary => true}, :export_name => 'prefix', :export_prefix => 'N'}
    new_custom_fields << {:name => 'Organizace', :attributes => {:field_format => 'string', :is_filter => true}, :export_name => 'org' }
    new_custom_fields << {:name => 'E-mail', :attributes => {:field_format => 'email', :is_filter => true, :is_primary => true}, :export_name => 'add_email' }
    new_custom_fields << {:name => 'Telefon', :attributes => {:field_format => 'string', :is_filter => true, :is_primary => true}, :export_name => 'add_tel' }
    new_custom_fields << {:name => 'Ulice', :attributes => {:field_format => 'string', :is_filter => true}, :export_prefix => 'ADR', :export_name => 'street' }
    new_custom_fields << {:name => 'Město', :attributes => {:field_format => 'string', :is_filter => true}, :export_prefix => 'ADR', :export_name => 'locality' }
    new_custom_fields << {:name => 'Kraj', :attributes => {:field_format => 'string', :is_filter => true}, :export_prefix => 'ADR', :export_name => 'region' }
    new_custom_fields << {:name => 'PSČ', :attributes => {:field_format => 'string', :is_filter => true}, :export_prefix => 'ADR', :export_name => 'postalcode' }
    new_custom_fields << {:name => 'Země', :attributes => {:field_format => 'string', :is_filter => true}, :export_prefix => 'ADR', :export_name => 'country' }

    p = EasyContactType.create(:type_name => 'Osobní', :position => 1, :is_default => true, :icon_path => 'user.png') unless p = EasyContactType.where(:type_name => 'Osobní').first
    g = EasyContactType.create(:type_name => 'Firemní', :position => 2, :is_default => false, :icon_path => 'group.png') unless g = EasyContactType.where(:type_name => 'Firemní').first

    new_custom_fields.each do |source|
      cf = EasyContactCustomField.find_or_initialize_by(name: source[:name])
      cf.contact_type_ids = cf.contact_type_ids | [p.id,g.id]
      if cf.new_record?
        cf.attributes = source[:attributes]
        cf.save!
      end
      CustomFieldMapping.create(:custom_field_id => cf.id, :format_type => 'vcard', :group_name => source[:export_prefix], :name => source[:export_name])
    end

  end

  def self.down
    EasyContactCustomField.all.each do |cf|
      CustomFieldMapping.where({:custom_field_id => cf.id}).destroy_all
      cf.destroy
    end

    EasyContactGroupCustomField.all.each do |cf|
      CustomFieldMapping.where({:custom_field_id => cf.id}).destroy_all
      cf.destroy
    end
  end
end
