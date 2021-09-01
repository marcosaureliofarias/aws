module EasyExtensions
  module Export
    module ExportHelper
      include ApplicationHelper
      include EntityAttributeHelper
      include Redmine::Hook::Helper
      include EasyExtensions::Export::PDFHelper
      include Redmine::I18n

      # *file_type = :csv | :pdf | :ical | ...
      # * args[0] = query | string | symbol
      # * args[1] = optional default string if query entity name is not in langfile
      def get_export_filename(file_type, *args)
        obj = args.first
        if obj.respond_to?(:entity)
          query  = obj
          entity = query.entity.name
          if query.new_record?
            name = l("label_#{entity.underscore}_plural", :default => args[1] || entity.underscore.humanize)
          else
            name = query.name
          end
        else
          name = obj && l(obj, :default => obj.to_s.humanize) || 'export'
        end

        return name + ".#{file_type}"
      end

    end
  end
end
