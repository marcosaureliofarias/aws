# frozen_string_literal: true

require 'fileutils'

module EasyUtils
  module EasyPage
    extend self

    # Import exported xml as eas page dashboard (build-in, not user-defined)
    #
    # @example Import from zip
    #   import_dashboard(page_name: 'my-page-overview', data_file: 'files/my_page_overview.zip')
    #
    # @param page_name [String] Page name
    # @param data_file [String] Path to the file (.xml or .zip)
    # @param version [Integer]
    #   Version (0..)
    #   Ensure actual version
    #
    def import_dashboard(page_name:, data_file:, version: 1, keep_templates: true)
      if ::EasyPage.where(page_name: page_name).where('version >= ?', version).exists?
        return
      end

      ::EasyPage.transaction do
        import_dashboard!(page_name: page_name, data_file: data_file, version: version, keep_templates: keep_templates)
      end
    end

    def import_dashboard!(page_name:, data_file:, version:, keep_templates:)
      if !File.exist?(data_file)
        raise ArgumentError, 'data_file does not exist'
      end

      if data_file.end_with?('.zip')
        tmpdir   = Dir.mktmpdir
        xml_file = File.join(tmpdir, 'data.xml')

        Zip::File.open(data_file) do |file|
          entry = file.find { |entry| entry.name == 'data.xml' }

          if entry
            entry.extract(xml_file)
          else
            raise ArgumentError, 'data_file does not contains data.xml'
          end
        end

      elsif data_file.end_with?('.xml')
        xml_file = data_file

      else
        raise ArgumentError, 'data_file should be a .zip or .xml'
      end

      current_easy_page = ::EasyPage.find_by(page_name: page_name)

      importer          = EasyXmlData::Importer.new
      importer.xml_file = xml_file
      importer.xml # Just touch importables
      importer.auto_mapping

      easy_pages_mapping = importer.importable_by_id('easy_page')&.entities_for_mapping

      if easy_pages_mapping&.size != 1
        error! 'File should contains exactly one EasyPage'
      end

      map = { 'identifier' => page_name.parameterize }

      if current_easy_page
        # You cannot call `destroy_all` on association where is `through` parameter
        current_easy_page.all_modules.each(&:destroy)
        current_easy_page.easy_page_tabs.destroy_all

        # Ensure that new content will be placed into existed EasyPage
        xml_easy_page_id      = easy_pages_mapping.first[:id]
        map[xml_easy_page_id] = current_easy_page.id
      end

      importer.add_map(map, 'easy_page')
      importer.import

      if importer.validation_errors.any?
        error! "Import failed: #{importer.validation_errors.join(', ')}"
      end

      page_importable = importer.imported.dig('easy_page', :importable)

      if page_importable.nil?
        error! 'No easy_page imported'
      end

      if current_easy_page
        if page_importable.processed_entities.size != 0
          error! 'Number of imported pages should be 0'
        else
          imported_easy_page = current_easy_page
        end
      else
        if page_importable.processed_entities.size != 1
          error! 'Number of imported pages should be 1'
        else
          _, imported_easy_page = page_importable.processed_entities.first
        end
      end

      imported_easy_page.page_name       = page_name
      imported_easy_page.is_user_defined = false
      imported_easy_page.has_template    = true
      imported_easy_page.page_scope      = nil
      imported_easy_page.version         = version
      imported_easy_page.save!

      if !keep_templates
        imported_easy_page.templates.destroy_all
      end

      template               = EasyPageTemplate.new
      template.easy_pages_id = imported_easy_page.id

      if version.zero?
        template.template_name = page_name.titleize
      else
        template.template_name = "#{page_name.titleize} v#{version}"
      end

      template.copy_from_type = 'regular_page'
      template.is_default     = true
      template.save!

      if block_given?
        yield imported_easy_page, template
      end

    ensure
      tmpdir && ::FileUtils.remove_entry(tmpdir)
    end

    def error!(message)
      raise EasyXmlData::Importer::CancelImportException, message
    end

    def import_dashboard_template!(data_file)
      if !File.exist?(data_file)
        raise ArgumentError, 'data_file does not exist'
      end

      importer = EasyXmlData::Importer.new_with_archived_file(data_file)
      importer.xml # Just touch importables
      importer.auto_mapping_ids = ['easy_page_template']
      importer.auto_mapping

      importer.import

      if importer.validation_errors.any?
        @error_messages << "Import of #{File.basename(data_file, '.*')} failed: #{importer.validation_errors.join(', ')}"
      end

      easy_page_template_importable = importer.imported.dig('easy_page_template', :importable)

      if easy_page_template_importable.nil?
        error! 'No EasyPageTemplate imported'
      end

      if easy_page_template_importable.processed_entities.size != 1
        error! 'Number of imported templates should be 1'
      else
        _, imported_easy_page_template = easy_page_template_importable.processed_entities.first
      end

      imported_easy_page_template
    ensure
      importer && importer.clear_import_dir
    end

  end
end
