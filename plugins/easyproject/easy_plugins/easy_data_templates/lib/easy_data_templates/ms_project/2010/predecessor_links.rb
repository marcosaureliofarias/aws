require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class PredecessorLinks < EasyXmlHelper::Xml::XmlNodeCollectionBase

      xml_collection_type EasyDataTemplates::MsProject2010::PredecessorLink, 'xmlns:PredecessorLink'

      def initialize(parent_xml_node)
        super(parent_xml_node, '.', parent_xml_node.namespaces)
      end

    end

  end
end
