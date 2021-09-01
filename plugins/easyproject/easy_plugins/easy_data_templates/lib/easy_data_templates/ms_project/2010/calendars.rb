require 'easy_xml_helper/xml/xml_node_collection_base'
require 'easy_data_templates/ms_project/2010/calendar'

module EasyDataTemplates
  module MsProject2010

    class Calendars < EasyXmlHelper::Xml::XmlNodeCollectionBase

      xml_collection_type EasyDataTemplates::MsProject2010::Calendar, 'xmlns:Calendar'

      def initialize(parent_xml_node)
        super(parent_xml_node, 'xmlns:Calendars', parent_xml_node.namespaces)
      end

    end

  end
end
