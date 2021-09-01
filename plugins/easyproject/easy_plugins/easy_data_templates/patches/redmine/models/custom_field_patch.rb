module EasyDataTemplates
  module EasyPatch
    module CustomFieldPatch

      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :form_fields, :easy_data_templates
        end
      end

      module InstanceMethods

        def form_fields_with_easy_data_templates
          fields = form_fields_without_easy_data_templates

          case self.class.name.to_sym
          when :IssueCustomField
            fields << :easy_do_not_export
          when :ProjectCustomField
            fields << :easy_do_not_export
          when :EasyProjectTemplateCustomField
            fields << :easy_do_not_export
          else
            fields
          end
        end

        def easy_do_not_export
          settings[:easy_do_not_export]
        end

        def easy_do_not_export=(do_not_export)
          settings[:easy_do_not_export] = (!do_not_export || do_not_export == '0') ? nil : true
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomField', 'EasyDataTemplates::EasyPatch::CustomFieldPatch'
