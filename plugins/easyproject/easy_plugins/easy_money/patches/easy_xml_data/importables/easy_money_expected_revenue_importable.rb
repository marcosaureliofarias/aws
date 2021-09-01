require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneyExpectedRevenueImportable < Importable

    def initialize(data = nil)
      @klass = EasyMoneyExpectedRevenue
      super
    end

    def mappable?
      true
    end

    def entities_for_mapping
      entities = []
      @xml.xpath('//easy_xml_data/easy-money-expected-revenues/*').each do |x|
        external_id = x.xpath('id').text.strip
        next if external_id.blank?
        match = @klass.where(:easy_external_id => external_id).first
        entities << {:id => external_id, :easy_external_id => external_id, :match => match ? match.id : ''}
      end
      entities
    end

    def before_record_save(record, xml, map)
      record.easy_external_id = xml.xpath('id').text.strip
    end

  end
end
