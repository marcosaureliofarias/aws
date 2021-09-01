require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class Task < EasyXmlHelper::Xml::XmlNodeBase

      xml_element :ctitical, 'xmlns:Critical', :integer
      xml_element :create_date, 'xmlns:CreateDate', :datetime
      xml_element :finish_date, 'xmlns:Finish', :date
      xml_element :id, 'xmlns:ID', :integer
      xml_element :is_published, 'xmlns:IsPublished', :integer
      xml_element :milestone, 'xmlns:Milestone', :integer
      xml_element :name, 'xmlns:Name', :string
      xml_element :percent_complete, 'xmlns:PercentComplete', :integer
      xml_element :percent_work_complete, 'xmlns:PercentWorkComplete', :integer
      xml_element :prioriy, 'xmlns:Priority', :integer
      xml_element :start_date, 'xmlns:Start', :date
      xml_element :summary, 'xmlns:Summary', :integer
      xml_element :type, 'xmlns:Type', :integer
      xml_element :uid, 'xmlns:UID', :integer
      xml_element :outline_level, 'xmlns:OutlineLevel', :integer
      xml_element :outlinenumber, 'xmlns:OutlineNumber', :string
      xml_element :work, 'xmlns:Work', :string
      xml_element :notes, 'xmlns:Notes', :string

      xml_collection :predecessor_links, EasyDataTemplates::MsProject2010::PredecessorLinks
      xml_collection :predecessors, EasyDataTemplates::MsProject2010::PredecessorLinks

    end

  end
end
