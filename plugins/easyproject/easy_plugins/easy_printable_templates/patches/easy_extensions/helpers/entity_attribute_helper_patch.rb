module EasyPrintableTemplates
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def format_html_easy_printable_template_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)
          case attribute.name
            when :name
              view_options = if params[:view_options] && (entity_options = params[:view_options][:easy_printable_templates])
                {
                  entity_type: entity_options[:entity_type],
                  entity_settings: entity_options[:entity_settings],
                  entity_id: (entity_options[:entity_id].presence || params[:query_id]),
                  back_url: entity_options[:back_url],
                  project_id: entity_options[:project_id],
                  selected_ids: entity_options[:selected_ids]
                }.delete_if{|_, v| v.blank? }
              else
                {}
              end

              if options[:entity]
                link_to(value, preview_easy_printable_template_path(options[:entity], view_options), onclick: 'easyModel.print.preview(this); return false;')
              else
                h(value)
              end

            else
              h(value)
          end
        end

        def format_easy_printable_template_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_default_entity_attribute(attribute, unformatted_value, options)

          value = case attribute.name
          when :pages_orientation
            EasyPrintableTemplate.translate_pages_orientation(value)
          else
            value
          end

          value
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyPrintableTemplates::EntityAttributeHelperPatch'
