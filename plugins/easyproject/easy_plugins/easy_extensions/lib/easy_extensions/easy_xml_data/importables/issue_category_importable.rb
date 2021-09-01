require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssueCategoryImportable < Importable

    def initialize(data)
      @klass = IssueCategory
      super
    end

    def mappable?
      true
    end

    private

    def entities_for_mapping
      categories = []
      @xml.xpath('//easy_xml_data/issue-categories/*').each do |category_xml|
        name  = category_xml.xpath('name').text
        match = IssueCategory.where(:name => name).first
        match = IssueCategory.create!(name: name) if match.blank? && allowed_to_create_entities?
        categories << { :id => category_xml.xpath('id').text, :name => name, :match => match ? match.id : '' }
      end
      categories
    end

  end
end
