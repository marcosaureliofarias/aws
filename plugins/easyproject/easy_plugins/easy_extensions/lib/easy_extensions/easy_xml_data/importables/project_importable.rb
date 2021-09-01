require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class ProjectImportable < Importable

    def mappable?
      false
    end

    def initialize(data)
      @klass = Project
      super
    end

    private

    def update_attribute(project, name, value, map, xml)
      case name
      when 'enabled_modules'
        update_enabled_modules(project, xml)
      when 'easy_custom_project_menus'
        update_easy_custom_project_menus(project, xml)
      else
        super
      end
    end

    def after_record_save(project, xml, map)
      # project parent can only be set on a saved project
      parent_id = xml.xpath('parent-id').text
      if parent_id.present?
        if map['project'][parent_id]
          project.safe_attributes = { 'parent_id' => map['project'][parent_id] }
          project.save
        end
      end
    end

    def update_enabled_modules(project, xml)
      modules = []
      xml.xpath('enabled-module/name').each do |module_xml|
        modules << module_xml.text
      end
      project.enabled_module_names = modules
    end

    def update_easy_custom_project_menus(project, xml)
      easy_custom_project_menus = []
      xml.xpath('easy-custom-project-menu').each do |menu_xml|
        easy_custom_project_menus[menu_xml.at_xpath('position').text.to_i] = {
            :project   => project,
            :menu_item => menu_xml.at_xpath('menu-item').text,
            :name      => menu_xml.at_xpath('name').text,
            :url       => menu_xml.at_xpath('url').text,
        }
      end
      easy_custom_project_menus.compact.reverse.each do |menu|
        # when project invalid,this code will raise error ROLLBACK ActiveRecord::NotNullViolation Mysql2::Error: Field 'project_id' ...
        # #validate? on project setted false, by this reason project will be always saved anyway
        # EasyCustomProjectMenu.create menu
        project.easy_custom_project_menus.build menu
      end
    end

    def before_record_save(record, xml, map)
      record.errors.add(:name) unless record.name.present?
      true
    end

    def validate?
      false
    end

  end
end
