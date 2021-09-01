require 'easy_xml_helper/xml/xml_node_collection_base'
require 'easy_data_templates/ms_project/2010/task'

module EasyDataTemplates
  module MsProject2010

    class Tasks < EasyXmlHelper::Xml::XmlNodeCollectionBase

      xml_collection_type EasyDataTemplates::MsProject2010::Task, 'xmlns:Task'

      def initialize(parent_xml_node)
        super(parent_xml_node, 'xmlns:Tasks', parent_xml_node.namespaces)
      end

    end

  end
end
