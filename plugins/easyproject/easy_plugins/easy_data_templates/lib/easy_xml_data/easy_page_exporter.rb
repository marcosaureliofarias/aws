module EasyXmlData
  class EasyPageExporter < Exporter
    require 'zip'

    def initialize(page_id)
      @page_id = page_id

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
        @pages.to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[easy_pages_id easy_page_available_zones_id easy_page_available_modules_id settings]
        )
        @easy_page_user_tabs.present? && @easy_page_user_tabs.to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[entity_id settings name],
          procs: [proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') },
                  proc { |options, record| options[:builder].tag!('name', record.name(translated: false)) }]
        )
        @easy_page_zone_modules.present? && @easy_page_zone_modules.sort_by(&:position).to_xml(
          builder: bob,
          skip_instruct: true,
          except: %i[uuid easy_pages_id easy_page_available_zones_id easy_page_available_modules_id position settings],
          procs: [proc { |options, record| options[:builder].tag!('id', record.id) },
                  proc { |options, record| options[:builder].tag!('easy-page', record.easy_pages_id) },
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

      @pages = EasyPage.where(id: @page_id)
      @easy_page_user_tabs = EasyPageUserTab.where(page_id: @page_id)
      @easy_page_zone_modules = EasyPageZoneModule.where(easy_pages_id: @page_id)
      @easy_translations = @easy_page_user_tabs.map(&:easy_translations).flatten
    end

    def set_default_metadata
      @metadata = { entity_type: EasyPage.to_s }
      page = @pages.first
      @metadata.merge!(name: page.user_defined_name) if page
    end

  end
end
