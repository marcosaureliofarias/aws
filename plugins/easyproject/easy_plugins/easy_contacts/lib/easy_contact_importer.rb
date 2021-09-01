# encoding: utf-8
#require 'easy_contact'
require 'csv'

class EasyContactImporter
  include Redmine::I18n
  attr_reader :importable_custom_fields

  def initialize
    @importable_attributes = [ImportableField.new(:firstname), ImportableField.new(:lastname)]
    @importable_custom_fields = CustomFieldMapping.joins(:custom_field)
                                                  .where(format_type: 'csv')
                                                  .map { |cf_m| ImportableField.new(cf_m.name, cf_m.custom_field) }
  end

  def importable_fields
    @importable_attributes + @importable_custom_fields
  end

  def last_import_errors
    @last_import_errors
  end

  def import_csv(filename, options = {})
    result = Array.new
    #custom_fields_ids = EasyContacts::CustomFields.contact_field_ids

    File.open(filename, "r:#{options[:encoding]}") do |file|
      csv = CSV.new(file, :headers => false, :col_sep => l(:general_csv_separator))

      @last_import_errors = []

      csv.shift unless options[:keep_headers]

      csv.each do |row|
        next if row.blank?
        custom_field_values = Hash.new
        easy_contact_attributes = {:firstname => row.shift, :lastname => row.shift, :custom_field_values => custom_field_values }
        easy_contact_attributes[:type_id] = EasyContactType.default.id

        row.each_with_index do |col, index|
          custom_field_values[@importable_custom_fields[index].try(:custom_field_id).to_s] = col
        end

        c = EasyContact.new
        c.attributes = easy_contact_attributes
        result << c

        @last_import_errors = c.errors unless c.valid?
      end
    end
    result
  end

  def self.import(filename)
    err = Array.new
    contacts = Array.new

    File.open("#{Rails.root}/#{filename}", 'r') { |f| contacts = Hash.from_xml(f)['subjects'] }

    # ! ! ! ! ! ! !! ! !
    typ = EasyContactType.where(["type_name REGEXP ?", '^[fF]iremní$']).first
    unless typ
      puts "Nelze najít typ !!!"
      return
    end
    self.find_or_create_custom_fields
    contacts.each do |contact|
      custom_field_values = Hash.new

      contact.each_pair do |key,val|
        case key
        when 'city'
          custom_field_values[@city.id.to_s] = val.to_s
        when 'registration-no'
          custom_field_values[@reg.id.to_s] = val.to_s
        when 'vat-no'
          custom_field_values[@vat.id.to_s] = val.to_s
        when 'zip'
          custom_field_values[@zip.id.to_s] = val.to_s
        when 'country'
          custom_field_values[@country.id.to_s] = val.to_s
        when 'street'
          custom_field_values[@street.id.to_s] = val.to_s
        when 'firstname'
          custom_field_values[@firstname.id.to_s] = val.to_s
        when 'surname'
          custom_field_values[@lastname.id.to_s] = val.to_s
        when 'web'
          custom_field_values[@web.id.to_s] = val.to_s
        when 'bank-account'
          custom_field_values[@bank.id.to_s] = val.to_s
        when 'email'
          custom_field_values[@mail.id.to_s] = val.to_s
        end
      end
      # Attributes for new contact
      easy_contact = {:type_id => typ.id, :contact_name => contact['name'], :custom_field_values => custom_field_values }

      # Create new contact
      c = EasyContact.new
      c.add_non_primary_custom_fields(custom_field_values)
      c.attributes = easy_contact

      # Save contact and log progress
      if c.save
        p "Contact '#{c.contact_name}' was successfully saved."
      else
        p "Saved failed on contact '#{c.contact_name} !"
        p c.errors.full_messages
        puts
        err << c.errors.full_messages
      end

    end
    puts '-------------------------------------'
    p "Successfully saved : #{contacts.size - err.size}. Not saved: #{err.size}"
    puts
    puts 'Errors:'
    puts err.uniq.join(' ; ')
    puts
    p 'Thx for using EasyContact importer :)'
  end

  private

  def self.find_or_create_custom_fields
    @city = EasyContacts::CustomFields.city

    @street = EasyContacts::CustomFields.street

    @zip = EasyContacts::CustomFields.postal_code

    @country = EasyContacts::CustomFields.country

    @firstname = EasyContactCustomField.find_by_name('Jméno')

    @lastname = EasyContactCustomField.find_by_name('Příjmení')

    @phone = EasyContacts::CustomFields.telephone

    @mail = EasyContacts::CustomFields.email

    @reg = EasyContactCustomField.find_or_initialize_by_name('fRegistration number')
    if @reg.new_record?
      @reg.attributes = {:field_format => 'string', :is_filter => true}
      @reg.save!
    end

    @vat = EasyContactCustomField.find_or_initialize_by_name('fVAT code')
    if @vat.new_record?
      @vat.attributes = {:field_format => 'string', :is_filter => true}
      @vat.save!
    end

    @iban = EasyContactCustomField.find_or_initialize_by_name('fIban')
    if @iban.new_record?
      @iban.attributes = {:field_format => 'string', :is_filter => true}
      @iban.save!
    end

    @web = EasyContactCustomField.find_or_initialize_by_name('fWebsite')
    if @web.new_record?
      @web.attributes = {:field_format => 'string', :is_filter => true}
      @web.save!
    end

    @bank = EasyContactCustomField.find_or_initialize_by_name('fBank account')
    if @bank.new_record?
      @bank.attributes = {:field_format => 'string', :is_filter => true}
      @bank.save!
    end
  end

  class ImportableField
    include Redmine::I18n
    attr_reader :attribute, :custom_field

    def initialize(attribute, custom_field=nil)
      @attribute = attribute
      @custom_field = custom_field
    end

    def is_custom_field?
      !@custom_field.nil?
    end

    def value(easy_contact)
      if self.is_custom_field?
        easy_contact.send(:custom_field_casted_value, @custom_field)
      else
        easy_contact.send(@attribute)
      end
    end

    def name
      is_custom_field? ? @custom_field.name : l("field_#{@attribute}")
    end

    def custom_field_id
      @custom_field && @custom_field.id.to_s
    end

  end
end
