require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WikiImportable < Importable

    def initialize(data)
      @klass = Wiki
      super
    end

    def mappable?
      false
    end

    def after_record_save(record, xml, map)
      # when the project is created, a corresponding empty wiki record is automatically created too
      # we need to check if there are such "ghosts" and eliminate it
      Wiki.where.not(id: record.id).where(project_id: record.project.id).each do |wiki|
        if wiki.pages.none?
          wiki.destroy
        else
          ep "Project##{record.project.id} already has a non-empty Wiki##{wiki.id}"
        end
      end
    end

  end
end