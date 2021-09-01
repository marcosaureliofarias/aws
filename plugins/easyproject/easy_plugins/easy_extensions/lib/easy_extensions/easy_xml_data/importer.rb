require 'fileutils'
Dir[File.dirname(__FILE__) + '/importables/*.rb'].each { |file| require file }

module EasyXmlData
  class Importer
    require 'zip'

    attr_writer :xml_file

    def initialize
      @id_mappings       = {}
      @auto_ids          = []
      @importables       = []
      @notifications     = false
      @manual_mapping    = []
      @validation_errors = []
    end

    def self.new_with_archived_file(archive_file)
      importer = self.new
      importer.save_archive_file(archive_file)
      importer
    end

    attr_writer :notifications
    attr_reader :validation_errors, :imported

    def save_archive_file(archive_file)
      clear_import_dir
      FileUtils.cp archive_file, File.join(import_dir, 'archive_file.zip')
    end

    def import_attachment_files(archive_file = nil)
      archive_file              ||= File.join(import_dir, 'archive_file.zip')
      imported_attachment_files = []
      if File.exists? archive_file
        Zip::File.open(archive_file) do |file|
          file.each do |entry|
            next unless entry.name.start_with?('attachments/')
            destination = File.join(Attachment.storage_path, entry.name.sub('attachments/', ''))
            ensure_folder_for_file(destination)
            unless File.exists?(destination)
              entry.extract(destination)
              imported_attachment_files << destination
            end
          end
        end
      end if File.exists? archive_file
      imported_attachment_files
    end

    def clear_import_dir
      import_dir = self.import_dir
      if File.exists? import_dir
        Dir["#{import_dir}/*"].each { |file| FileUtils.rm_r(file) }
      else
        FileUtils.mkdir_p(import_dir)
      end
    end

    def import_dir
      @import_dir ||= File.join(Attachment.storage_path, 'easy_xml_data_import_data', User.current.id.to_s)
      @import_dir
    end

    def xml
      return @xml if @xml

      xml_file = @xml_file || File.join(import_dir, 'data.xml')
      unless File.exists? xml_file
        archive_file = File.join(import_dir, 'archive_file.zip')
        begin
          Zip::File.open(archive_file) do |file|
            entry = file.find { |entry| entry.name == 'data.xml' }
            entry.extract(File.join(import_dir, entry.name)) if entry
          end
        rescue
          return
        end
      end

      @xml = Nokogiri::XML(File.read(xml_file), &:noblanks) if File.exist?(xml_file)
      set_importables if @xml

      @xml
    end

    def import(skip_associations = false)
      if @importables.select { |i| i.mappable? && !i.mapped? }.any?
        raise StandardError, 'Cannot start import until everything is mapped'
      end
      @imported = Hash.new
      if @importables.empty?
        @validation_errors << I18n.t(:label_no_data)
      else
        Mailer.with_deliveries(@notifications) do
          @importables.each do |importable|
            begin
              @imported[importable.id] = { :map => importable.import(@id_mappings, skip_associations), :importable => importable }
            rescue => e
              importable.validation_errors.present? || importable.validation_errors << I18n.t('internal_server_error.title')
              ep(e.to_s)
              break
            ensure
              @validation_errors << importable.validation_errors
            end
          end
        end
        import_attachment_files if importable_by_id(Attachment.name.underscore)
      end
      @validation_errors.flatten!
      clear_import_dir

      return self
    end

    def manual_mapping_data
      xml # touch
      mapping_data = []
      @importables.each do |importable|
        next if (!importable.mappable? || @auto_ids.include?(importable.id))
        mapping_data << importable.mapping_data
      end
      mapping_data
    end

    def add_map(map, entity_type)
      xml # touch
      id_map = {}
      map.each do |map_from, map_to|
        if map_to != ''
          id_map[map_from] = map_to
        end
      end
      @id_mappings[entity_type] = id_map
      importable                = importable_by_id(entity_type)
      unless importable.blank?
        importable.custom_mapping(@id_mappings) if importable.respond_to?(:custom_mapping)
        importable.mapped = true
      end
    end

    def importable_ids
      @importables.map(&:id)
    end

    def importable_by_id(id)
      @importables.detect { |importable| importable.id == id }
    end

    def auto_mapping_ids=(auto_ids)
      @auto_ids = auto_ids
    end

    def auto_mapping
      auto_ids = @auto_ids.dup
      auto_ids = [] unless auto_ids.is_a? Array
      @importables.each do |importable|
        if importable.mappable? && auto_ids.include?(importable.id)
          id, entities_for_mapping, existing_entities = importable.mapping_data
          map                                         = {}
          entities_for_mapping.each do |mapping_data|
            map[mapping_data[:id]] = mapping_data[:match].to_s
          end
          @id_mappings[id] = map
          importable.custom_mapping(@id_mappings) if importable.respond_to?(:custom_mapping)
          importable.mapped = true
        end
      end
      ep @id_mappings
      @id_mappings
    end

    def metadata_xml
      return @metadata_xml if @metadata_xml
      metadata_file = File.join(import_dir, 'metadata.xml')
      unless File.exists? metadata_file
        archive_file = File.join(import_dir, 'archive_file.zip')
        begin
          Zip::File.open(archive_file) do |file|
            entry = file.find { |entry| entry.name == 'metadata.xml' }
            entry.extract(File.join(import_dir, entry.name)) if entry
          end
        rescue
          return
        end
      end

      if File.exist?(metadata_file)
        @metadata_xml = Nokogiri::XML(File.read(metadata_file), &:noblanks)
      end
      @metadata_xml
    end

    def meta_data
      metadata_xml = self.metadata_xml
      meta_data    = {}
      if metadata_xml.present?
        allowed_metadata = %i[author entity_type entity_count name description]
        allowed_metadata.each do |metadata_key|
          xpath                   = "//#{metadata_key.to_s.dasherize}"
          meta_data[metadata_key] = metadata_xml.xpath(xpath).text.presence
        end
      end
      meta_data[:entity_type] ||= find_imported_entity_type

      meta_data
    end

    # when no metadata found - legacy exports
    def find_imported_entity_type
      xml = self.xml
      if xml.blank?
        nil
      elsif xml.xpath('easy_xml_data/projects').present?
        project_xml = xml.xpath('easy_xml_data/projects').first
        project_xml.xpath('easy_is_easy_template') ? 'ProjectTemplate' : 'Project'
      elsif xml.xpath('easy_xml_data/easy-pages').present?
        'EasyPage'
      elsif xml.xpath('easy_xml_data/easy-page-templates').present?
        'EasyPageTemplate'
      end
    end

    private

    def ensure_folder_for_file(file)
      dirname = File.dirname(file)
      ensure_folder dirname
    end

    def ensure_folder(dirname)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

    def set_importable(importable_class, xpath = nil)
      xpath ||= importable_class.xpath
      if (importable_xml = @xml.xpath(xpath)).present?
        @importables << importable_class.new(xml: importable_xml)
      end
    end

    def set_importables
      return false if @importables_set
      set_importable UserImportable, '//easy_xml_data/users/*'
      set_importable GroupImportable, '//easy_xml_data/groups/*'
      set_importable ProjectCustomFieldImportable, '//easy_xml_data/project-custom-fields/*'
      set_importable EasyProjectTemplateCustomFieldImportable, '//easy_xml_data/easy-project-template-custom-fields/*'
      set_importable IssueCustomFieldImportable, '//easy_xml_data/issue-custom-fields/*'
      set_importable IssueStatusImportable, '//easy_xml_data/issue-statuses/*'
      set_importable TrackerImportable, '//easy_xml_data/trackers/*'
      set_importable ProjectImportable, '//easy_xml_data/projects/*'
      set_importable EasyPageImportable, '//easy_xml_data/easy-pages/*'
      set_importable EasyPageTemplateImportable, '//easy_xml_data/easy-page-templates/*'
      set_importable EasyPageTemplateTabImportable, '//easy_xml_data/easy-page-template-tabs/*'
      set_importable EasyPageUserTabImportable, '//easy_xml_data/easy-page-user-tabs/*'
      set_importable EasyPageTemplateModuleImportable, '//easy_xml_data/easy-page-template-modules/*'
      set_importable EasyPageZoneModuleImportable, '//easy_xml_data/easy-page-zone-modules/*'
      set_importable RoleImportable, '//easy_xml_data/roles/*'
      set_importable MemberImportable, '//easy_xml_data/members/*'
      set_importable VersionImportable, '//easy_xml_data/versions/*'
      set_importable IssuePriorityImportable, '//easy_xml_data/issue-priorities/*'
      set_importable IssueCategoryImportable, '//easy_xml_data/issue-categories/*'
      set_importable IssueImportable, '//easy_xml_data/issues/*'
      set_importable IssueRelationImportable, '//easy_xml_data/issue-relations/*'
      set_importable WorkflowRuleImportable, '//easy_xml_data/workflow_rules/*'
      set_importable NewsImportable, '//easy_xml_data/news/*'
      set_importable CommentImportable, '//easy_xml_data/comments/*'
      set_importable DocumentCategoryImportable, '//easy_xml_data/document-categories/*'
      set_importable DocumentImportable, '//easy_xml_data/documents/*'
      set_importable TimeEntryActivityImportable, '//easy_xml_data/time-entry-activities/*'
      set_importable ProjectActivityImportable, '//easy_xml_data/project-activities/*'
      set_importable ProjectActivityRoleImportable, '//easy_xml_data/project-activity-roles/*'
      set_importable TimeEntryImportable, '//easy_xml_data/time-entries/*'
      set_importable AttachmentImportable, '//easy_xml_data/attachments/*'
      set_importable AttachmentVersionImportable, '//easy_xml_data/attachment-versions/*'
      set_importable JournalImportable, '//easy_xml_data/journals/*'
      set_importable WikiImportable, '//easy_xml_data/wikis/*'
      set_importable WikiPageImportable, '//easy_xml_data/wiki-pages/*'
      set_importable WikiContentImportable, '//easy_xml_data/wiki-contents/*'
      set_importable WikiContentVersionImportable, '//easy_xml_data/wiki-content-versions/*'
      set_importable WikiRedirectImportable, '//easy_xml_data/wiki-redirects/*'
      set_importable EasyTranslationImportable

      Redmine::Hook.call_hook(:easy_xml_data_import_importer_set_importable, { xml: @xml, importables: @importables })

      @importables_set = true
    end

    class CancelImportException < StandardError

    end

  end
end

def ep(object, settings = 'g')
  return if Rails.env.test?

  @log ||= Logger.new(Rails.root.join('log', "easy_xml_data_importer.log"))

  otpt = object.is_a?(String) ? object : object.pretty_inspect.strip

  @log.info otpt
end
