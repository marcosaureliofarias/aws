module EasyXmlData
  class EasyPageTemplateExporter < Exporter
    require 'zip'

    def initialize(page_template_id)
      @page_template_id = page_template_id

      collect_entities
      set_default_metadata
    end

    def self.exportables
      @exportables ||= []
    end

    def self.exportable_labels
      @exportable_labels ||= Hash.new
    end

    def build_xml(bob)
      bob.easy_xml_data do
        @page_templates.to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[easy_pages_id is_default position],
          procs: [proc { |options, record| options[:builder].tag!('easy-page', record.page_definition.page_name) }]
        )
        @easy_page_template_tabs.present? && @easy_page_template_tabs.to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[entity_id settings name],
          procs: [proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') },
                  proc { |options, record| options[:builder].tag!('name', record.name(translated: false)) }]
        )
        @easy_page_template_modules.present? && @easy_page_template_modules.sort_by(&:position).to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[uuid easy_page_templates_id easy_page_available_zones_id easy_page_available_modules_id position settings],
          procs: [proc { |options, record| options[:builder].tag!('id', record.id) },
                  proc { |options, record| options[:builder].tag!('easy-page-template', record.easy_page_templates_id) },
                  proc { |options, record| options[:builder].tag!('easy-page-zone', record.zone_definition.zone_name) },
                  proc { |options, record| options[:builder].tag!('easy-page-module', record.module_definition.type) },
                  proc do |options, record|
                    record.do_not_translate = true
                    options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml')
                  end]
        )
        @easy_translations.present? && @easy_translations.to_xml(
          builder: bob,
          skip_instruct: true
        )
      end
    end

    private

    def collect_entities
      @attachment_files = []
      @attachment_versions = []

      @page_templates = EasyPageTemplate.where(id: @page_template_id)
      @easy_page_template_tabs = EasyPageTemplateTab.where(page_template_id: @page_template_id)
      @easy_page_template_modules = EasyPageTemplateModule.where(easy_page_templates_id: @page_template_id)
      @easy_translations = @easy_page_template_tabs.map(&:easy_translations).flatten
    end

    def set_default_metadata
      @metadata = { entity_type: EasyPageTemplate.to_s }
      page_template = @page_templates.first
      @metadata.merge!(name: page_template.template_name, description: page_template.description) if page_template
    end

  end
end
