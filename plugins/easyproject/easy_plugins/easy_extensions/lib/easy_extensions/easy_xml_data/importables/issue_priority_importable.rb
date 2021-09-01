require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssuePriorityImportable < Importable

    def initialize(data)
      @klass = IssuePriority
      super
    end

    def mappable?
      true
    end

    private

    def entities_for_mapping
      priorities = []
      @xml.xpath('//easy_xml_data/issue-priorities/*').each do |priority_xml|
        name  = priority_xml.xpath('name').text
        match = IssuePriority.where(:name => name).first
        match = IssuePriority.create!(name: name) if match.blank? && allowed_to_create_entities?
        priorities << { :id => priority_xml.xpath('id').text, :name => name, :match => match ? match.id : '' }
      end
      priorities
    end

  end
end
