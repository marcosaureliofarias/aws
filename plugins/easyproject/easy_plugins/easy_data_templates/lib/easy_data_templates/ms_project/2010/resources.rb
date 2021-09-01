require 'easy_xml_helper/xml/xml_node_collection_base'
require 'easy_data_templates/ms_project/2010/resource'

module EasyDataTemplates
  module MsProject2010

    class Resources < EasyXmlHelper::Xml::XmlNodeCollectionBase

      xml_collection_type EasyDataTemplates::MsProject2010::Resource, 'xmlns:Resource'

      def initialize(parent_xml_node)
        super(parent_xml_node, 'xmlns:Resources', parent_xml_node.namespaces)
      end

    end

  end
end
