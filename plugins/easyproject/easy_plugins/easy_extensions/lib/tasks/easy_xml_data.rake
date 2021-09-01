namespace :easyproject do
  namespace :easy_xml_data do

    desc <<-END_DESC
    Exports all projects into an XML archive. Will overwrite the current archive file!

    Example:
      bundle exec rake easyproject:easy_xml_data:export_all_projects RAILS_ENV=production
    END_DESC
    task export_all: :environment do
      EasyXmlData::Exporter.new(EasyXmlData::Exporter.exportables, Project.all.pluck(:id)).build_archive
    end

    desc <<-END_DESC
    Exports specified projects into an XML archive, Will overwrite the current archive file!
    PROJECT_IDS="1,2,3" the IDs of the projects to export, both numeric IDs and identifiers are allowed.
    WITH_SUBPROJECTS=true if you want to recursive export the subprojects too.

    Example
      bundle exec rake easyproject:easy_xml_data:export_projects PROJECT_IDS="project1,project2" RAILS_ENV=production
    END_DESC
    task export_projects: :environment do
      raw_project_ids = ENV['PROJECT_IDS']
      fail 'PROJECT_IDS environment variable must be specified!' unless raw_project_ids.present?
      num_project_ids = raw_project_ids.split(',').map do |raw_project_id|
        if raw_project_id.to_i > 0 && Project.where(id: raw_project_id.to_i).exists?
          raw_project_id.to_i
        else
          Project.where(identifier: raw_project_id).first&.id
        end
      end.compact
      fail 'No exportable projects found. Please double check the IDs you supplied!' if num_project_ids.empty?

      if ENV['WITH_SUBPROJECTS'].to_boolean
        sub_project_ids = num_project_ids.map{ |project_id| Project.find(project_id).descendants.pluck(:id) }.flatten
        num_project_ids = (num_project_ids + sub_project_ids).uniq
      end

      EasyXmlData::Exporter.new(EasyXmlData::Exporter.exportables, num_project_ids).build_archive
    end

    desc <<-END_DESC
    Imports entities from the specified XML archive.
    EASY_EXPORT_SKIP_VALIDATION=true if you want to skip validation of the importable entities.
    EASY_EXPORT_CREATE_ENTITIES=true if you want to allow to create mappable entities which are missing.

    Example:
      bundle exec rake easyproject:easy_xml_data:import XML_ARCHIVE_FILE=/path/to/archive/file.zip RAILS_ENV=production
    END_DESC
    task import: :environment do
      xml_archive_file = ENV['XML_ARCHIVE_FILE']
      fail 'XML_ARCHIVE_FILE environment variable must be specified!' unless xml_archive_file.present?
      fail 'XML_ARCHIVE_FILE environment variable must contain path to the existing file!' unless File.exists? xml_archive_file

      File.open(xml_archive_file) do |file|
        importer = EasyXmlData::Importer.new_with_archived_file file
        importer.meta_data
        importer.auto_mapping_ids = EasyXmlData::Importable.descendants.map{|klass| klass.name.split('::')[1].chomp('Importable').underscore if klass.new(nil).mappable?}.compact
        xml = importer.xml
        mappings = importer.auto_mapping
        importer.import
      end
    end

  end
end
