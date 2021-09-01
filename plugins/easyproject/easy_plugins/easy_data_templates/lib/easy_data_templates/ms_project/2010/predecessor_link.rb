require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class PredecessorLink < EasyXmlHelper::Xml::XmlNodeBase

      RELATION_TYPES = {
        finish_to_finish: 0,
        finish_to_start: 1,
      }

      xml_element :predecessor_uid, 'xmlns:PredecessorUID', :integer
      xml_element :type, 'xmlns:Type', :integer
      xml_element :cross_project, 'xmlns:CrossProject', :integer
      xml_element :link_lag, 'xmlns:LinkLag', :integer
      xml_element :lag_format, 'xmlns:LagFormat', :integer

      def relation_type
        case type
        # TODO: implement, works only in gantt?
        # when RELATION_TYPES[:finish_to_finish]
        when RELATION_TYPES[:finish_to_start]
          'follows'
        end
      end

      # @note converts MS delay to EasyProject Delay
      def relation_delay
        # TODO: implement, no data with MS project delay atm
      end

    end

  end
end
