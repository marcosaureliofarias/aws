class EasyEntityXmlImport < EasyEntityImport

  attr_reader :xml, :root_node

  def import_format
    :xml
  end

  def root_xpath
    if !@root_xpath && (@root_xpath = settings['root'].presence)
      @root_xpath.prepend('//') unless @root_xpath.starts_with?('/')
    end

    @root_xpath
  end

  def process_preview_file
    get_xml
    root = self.settings['root'].presence
    @root_node = root if root && @xml.xpath(root_xpath).first
    @root_node = @xml.root.name if !@root_node && @xml.root
    raise ArgumentError, 'Cannot find the root node' unless @root_node

    return @xml
  end

  def transform_xml
    doc = @xml || get_xml
    template = Nokogiri::XSLT(get_xslt)
    x = template.transform(doc)
    x.remove_namespaces!

    return x
  end

  def get_xml
    @xml ||= Nokogiri::XML.parse(@file && @file.read.tr("\n\r\t", '') || self.get_file)
    @xml
  end

  def get_xslt
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send('xsl:stylesheet', 'version' => '1.0', 'xmlns' => 'default', 'xmlns:xsl' => 'http://www.w3.org/1999/XSL/Transform',
               'xmlns:math' => 'http://exslt.org/math', 'extension-element-prefixes' => 'math') do
        xml.send('xsl:output', 'method' => 'xml', 'encoding' => 'utf-8')
        xml['xsl'].template('match' => '/') do
          xml.easy_xml_data do
            xml_entity_name = self.entity_type.to_s.underscore.dasherize
            xml.send(xml_entity_name.pluralize) do
              if root_xpath
                xml.send('xsl:for-each', select: root_xpath) do
                  add_xml_entity(xml, xml_entity_name)
                end
              else
                add_xml_entity(xml, xml_entity_name)
              end
            end
          end
        end
      end
    end

    return builder.to_xml
  end

  def import(file=nil)
    if file
      @xml = Nokogiri::XML.parse(file.try(:read) || file)
    end
    tmp_file = 'tmp/importable_xslt.xml'
    File.open(tmp_file, 'w') { |x| x.puts get_xslt }
    tmp_file = 'tmp/importable_xml.xml'
    File.open(tmp_file, 'w') { |x| x.puts transform_xml }

    entity_name = self.entity_type.underscore

    importer = EasyXmlData::Importer.new
    importer.xml_file = tmp_file
    importer.xml # touch
    importer.auto_mapping_ids = [entity_name]
    importer.auto_mapping

    result = importer.import(true)

    raise StandardError.new(result.validation_errors.join('<br />')) if result.validation_errors.any?

    return {} unless result && result.imported[entity_name]

    processed_entities = result.imported[entity_name][:importable].processed_entities
    processed_entities.each do |external_id, imported|
      unless imported.new_record?
        imported.update_column(:easy_external_id, external_id)
        imported.copy(template) if template
      end

    end if self.entity_class.column_names.include?('easy_external_id')

    return processed_entities
  end

  private

  def add_xml_entity(xml, xml_entity_name)
    xml.send(xml_entity_name, nil) do
      cfs = []
      self.easy_entity_import_attributes_assignments.each do |att|
        if att.source_attribute.present? && r = att.source_attribute.match(/.*\[\*\]\/(.*)/)
          att.source_attribute = r[1]
        end
        if att.entity_attribute.match(/^cf_\d+/)
          cfs << att
          next
        end
        add_select_attribute(xml, att)
      end
      if cfs.any?
        xml.send('custom_fields', :type => 'Array') do
          cfs.each do |att|
            cf_id = att.entity_attribute.match(/^cf_(\d+)/)[1]
            next if cf_id.nil?
            xml.send('custom_field', :id => cf_id) do
              xml.value do
                if att.is_custom?
                  att.value
                else
                  add_xsl_value(xml, att, {:custom_field => CustomField.where(:id => cf_id).first})
                end
              end
            end
          end
        end
      end
      add_other_attributes(xml)
    end
  end

  def add_other_attributes(xml)
    # TODO
  end

  def add_select_attribute(xml, att)
    if att.is_custom?
      if att.value == ':rnd'
        xml.send(att.entity_attribute) do
          xml.send('xsl:value-of', 'select' => "(floor(math:random()*100) mod 100) + 1")
        end
      else
        xml.send(att.entity_attribute, att.value)
      end
    else
      xml.send(att.entity_attribute) do
        add_xsl_value(xml, att)
      end
    end
  end

  def add_xsl_value(xml, att, options={})
    if att.default_value.present?
      xml['xsl'].if('test' => "#{att.source_attribute} = ''") do
        xml['xsl'].text(att.default_value)
      end
      xml['xsl'].if('test' => "not(#{att.source_attribute} = '')") do
        if options[:custom_field] && options[:custom_field].multiple?
          xml.send('xsl:copy-of', 'select' => "#{att.source_attribute}/*")
        else
          xml.send('xsl:value-of', 'select' => att.source_attribute)
        end
      end
    else
      if options[:custom_field] && options[:custom_field].multiple?
        xml.send('xsl:copy-of', 'select' => "#{att.source_attribute}/*")
      else
        xml.send('xsl:value-of', 'select' => att.source_attribute)
      end
    end
  end
end
