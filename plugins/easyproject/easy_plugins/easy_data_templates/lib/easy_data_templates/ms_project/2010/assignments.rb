require 'easy_xml_helper/xml/xml_node_collection_base'
require 'easy_data_templates/ms_project/2010/assignment'

module EasyDataTemplates
  module MsProject2010

    class Assignments < EasyXmlHelper::Xml::XmlNodeCollectionBase

      xml_collection_type EasyDataTemplates::MsProject2010::Assignment, 'xmlns:Assignment'

      def initialize(parent_xml_node)
        super(parent_xml_node, 'xmlns:Assignments', parent_xml_node.namespaces)
      end

    end

  end
end
