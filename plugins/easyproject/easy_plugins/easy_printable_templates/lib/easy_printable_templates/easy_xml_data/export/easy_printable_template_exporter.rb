module EasyXmlData
  class EasyPrintableTemplateExporter < ::EasyXmlData::Exporter
    require 'zip'

    def initialize(printable_template_ids)
      @printable_template_ids = printable_template_ids

      collect_entities
      set_default_metadata
    end

    def self.exportables
      @exportables ||= [:attachments]
    end

    def build_xml(builder)
      builder.easy_xml_data do
        @users.to_xml(
          builder: builder,
          skip_instruct: true,
          except: %i[easy_user_type easy_zoom_user_uid],
          procs: [
            proc { |options, record| options[:builder].tag!('easy-user-type-id', record.easy_user_type_id);
            options[:builder].tag!('mail', record.mail)
            }
          ]
        )
        @printable_templates.to_xml(
          builder: builder,
          skip_instruct: true
        )
        @easy_printable_template_pages.to_xml(
          builder: builder,
          skip_instruct: true,
          except: %i[position]
        )
        @attachments.to_xml(
          builder: builder,
          skip_instruct: true
        ) if @attachments.present?
        @attachment_versions.to_xml(
          builder: builder,
          skip_instruct: true
        ) if @attachment_versions.present?
      end
    end

    private

    def collect_entities
      @printable_templates = EasyPrintableTemplate.where(id: @printable_template_ids).to_a
      user_ids = @printable_templates.map(&:author_id)
      @easy_printable_template_pages = EasyPrintableTemplatePage.where(easy_printable_template_id: @printable_template_ids).to_a

      if EasyPrintableTemplate.respond_to?(:attachments)
        @attachments, @attachment_versions = Array.new(2) { [] }
        @printable_templates.each { |pt| @attachments.concat pt.attachments }
        user_ids.concat @attachments.map(&:author_id)
        @attachment_versions = @attachments.map(&:versions).flatten
        user_ids.concat @attachment_versions.map(&:author_id)
      end
      @users = User.where(id: user_ids.uniq).to_a

    end

    def set_default_metadata
      @metadata = { entity_type: EasyPrintableTemplate.to_s }
      printable_template = @printable_templates.first
      @metadata.merge!(name: printable_template.name, description: printable_template.description) if printable_template
    end

  end
end
