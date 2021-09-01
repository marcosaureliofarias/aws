module EasyPatch
  module DocumentsHelperPatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def documents_to_csv(documents, query)
          export = Redmine::Export::CSV.generate do |csv|
            # csv header fields
            headers = Array.new
            query.columns.each do |c|
              headers << c.caption
            end
            headers << l(:field_filename)
            headers << l(:field_author)
            headers << "#{l(:field_filename)} #{l(:field_created_on).downcase}"
            csv << headers
            # csv lines
            documents.each do |entity|
              entity.attachments.each do |file|
                fields = Array.new
                query.columns.each do |column|
                  fields << format_value_for_export(entity, column)
                end
                fields << file.filename
                fields << file.author.name
                fields << format_time(file.created_on)
                csv << fields
              end
            end
          end

          export
        end

      end

    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'DocumentsHelper', 'EasyPatch::DocumentsHelperPatch'
