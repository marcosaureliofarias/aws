module EasyPrintableTemplates
  module EasyQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :query_after_initialize, :easy_printable_templates

      end
    end

    module InstanceMethods

      def query_after_initialize_with_easy_printable_templates
        query_after_initialize_without_easy_printable_templates

        if self.export_formats.is_a?(Hash) && !self.export_formats.empty? && User.current.allowed_to_globally?(:view_easy_printable_templates)
          url = { controller: 'easy_printable_templates', action: 'template_chooser', format: nil, entity_type: self.class.name }
          url[:project_id] = project_id if project_id
          self.export_formats[:print] = { caption: l(:button_print), url: url, remote: true, add_back_url: true, add_query_params: 'entity_settings' }
        end

      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyQuery', 'EasyPrintableTemplates::EasyQueryPatch'
