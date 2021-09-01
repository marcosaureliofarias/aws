require 'easy_xml_helper/xml/xml_parser'

require 'easy_data_templates/ms_project/2010/assignment'
require 'easy_data_templates/ms_project/2010/assignments'
require 'easy_data_templates/ms_project/2010/calendar'
require 'easy_data_templates/ms_project/2010/calendars'
require 'easy_data_templates/ms_project/2010/resource'
require 'easy_data_templates/ms_project/2010/resources'
require 'easy_data_templates/ms_project/2010/predecessor_link'
require 'easy_data_templates/ms_project/2010/predecessor_links'
require 'easy_data_templates/ms_project/2010/task'
require 'easy_data_templates/ms_project/2010/tasks'
require 'easy_data_templates/ms_project/2010/project'

module EasyDataTemplates
  module MsProject

    class MsProject2010XmlParser < EasyXmlHelper::Xml::XmlParser

      CHECKED_VALUE = 1

      def assign_root_element
        @root_element = EasyDataTemplates::MsProject2010::Project.new(self)
      end
      alias_method :project, :root_element

      def inspect
        self.to_s
      end

    end
  end
end
