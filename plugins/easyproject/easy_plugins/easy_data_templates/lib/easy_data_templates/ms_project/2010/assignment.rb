require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class Assignment < EasyXmlHelper::Xml::XmlNodeBase

      xml_element :finish_date, 'xmlns:Finish', :datetime
      xml_element :percent_work_complete, 'xmlns:PercentWorkComplete', :integer
      xml_element :resource_uid, 'xmlns:ResourceUID', :integer
      xml_element :start_date, 'xmlns:Start', :datetime
      xml_element :task_uid, 'xmlns:TaskUID', :integer
      xml_element :uid, 'xmlns:UID', :integer

    end

  end
end
