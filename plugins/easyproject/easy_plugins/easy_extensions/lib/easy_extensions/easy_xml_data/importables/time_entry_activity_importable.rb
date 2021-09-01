require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class TimeEntryActivityImportable < Importable

    def initialize(data)
      @klass = TimeEntryActivity
      super
    end

    def mappable?
      true
    end

    def entities_for_mapping
      time_entry_activities = []
      @xml.xpath('//easy_xml_data/time-entry-activities/*').each do |time_entry_activity_xml|
        name  = time_entry_activity_xml.xpath('name').text
        match = TimeEntryActivity.where(:name => name).first
        match = TimeEntryActivity.create!(:name => name) if match.blank? && allowed_to_create_entities?
        time_entry_activities << { :id => time_entry_activity_xml.xpath('id').text, :name => name, :match => match ? match.id : '' }
      end
      time_entry_activities
    end

  end
end