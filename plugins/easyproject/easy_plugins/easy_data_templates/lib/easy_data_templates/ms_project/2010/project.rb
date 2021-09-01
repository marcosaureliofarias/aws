require 'easy_xml_helper/xml/xml_node_base'

module EasyDataTemplates
  module MsProject2010

    class Project < EasyXmlHelper::Xml::XmlNodeBase

      xml_element :author, 'xmlns:Author', :string
      xml_element :create_date, 'xmlns:CreationDate', :datetime
      xml_element :finish_date, 'xmlns:FinishDate', :date
      xml_element :start_date, 'xmlns:StartDate', :date
      xml_element :title, 'xmlns:Title', :string
      xml_element :name, 'xmlns:Name', :string

      xml_collection :assignments, EasyDataTemplates::MsProject2010::Assignments
      xml_collection :calendars, EasyDataTemplates::MsProject2010::Calendars
      xml_collection :resources, EasyDataTemplates::MsProject2010::Resources
      xml_collection :tasks, EasyDataTemplates::MsProject2010::Tasks

      def initialize(xml_parser)
        current_xml_node = self.class.get_xml_node_set(xml_parser.xml_doc, 'xmlns:Project', xml_parser.xml_doc.namespaces).first

        raise ArgumentError, 'Cannot find a root element xmlns:Project inside a XML file.' unless current_xml_node

        super(current_xml_node)
      end

      def assignments_by_resource(resource)
        self.assignments.select{|a| a.resource_uid == resource.uid}
      end

      def assignments_by_task(task)
        self.assignments.select{|a| a.task_uid == task.uid}
      end

      def tasks_by_uid(uid)
        self.tasks && self.tasks.detect{|t| t.uid == uid}
      end

      def versions(options = {})
        checked_value = MsProject::MsProject2010XmlParser::CHECKED_VALUE
        tasks.select { |t| t.milestone == checked_value || (options[:include_summaries] && t.summary == checked_value) }
      end

      def issues(options = {})
        include_summaries = options.fetch(:include_summaries, true)
        checked_value = MsProject::MsProject2010XmlParser::CHECKED_VALUE

        tasks.select { |t| t.milestone != checked_value && (include_summaries || t.summary != checked_value) }
      end

    end

  end
end
