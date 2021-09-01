require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class Resource < EasyXmlHelper::Xml::XmlNodeBase

      xml_element :calendar_uid, 'xmlns:CalendarUID', :integer
      xml_element :is_cost_resource, 'xmlns:IsCostResource', :integer
      xml_element :is_generic, 'xmlns:IsGeneric', :integer
      xml_element :name, 'xmlns:Name', :string
      xml_element :type, 'xmlns:Type', :string
      xml_element :uid, 'xmlns:UID', :integer

    end

  end
end
