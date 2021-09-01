require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class Calendar < EasyXmlHelper::Xml::XmlNodeBase

      xml_element :name, 'xmlns:Name', :string
      xml_element :uid, 'xmlns:UID', :integer

    end

  end
end
