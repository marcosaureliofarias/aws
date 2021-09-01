module EasyPrintableTemplates
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_printable_template_query_additional_ending_buttons(entity, options = {})
          links = ''
          if options[:easy_printable_templates] && options[:easy_printable_templates][:show_print_button]
            link_options = {
              id: entity.id,
              entity_type: options[:easy_printable_templates][:entity_type],
              entity_id: options[:easy_printable_templates][:entity_id],
              back_url: options[:easy_printable_templates][:back_url],
              entity_settings: options[:easy_printable_templates][:entity_settings],
              project_id: options[:easy_printable_templates][:project_id],
              selected_ids: options[:easy_printable_templates][:selected_ids]
            }.delete_if{|_k,v| v.blank? }

            links << link_to(
              l(:button_easy_printable_templates_preview_and_print),
              preview_easy_printable_template_path(link_options),
              class: 'icon icon-watcher',
              title: l(:button_easy_printable_templates_preview_and_print),
              onclick: 'easyModel.print.preview(this); return false;'
            )
            links << link_to(
              l(:button_easy_printable_templates_generate_docx),
              generate_docx_from_attachment_easy_printable_template_path(link_options),
              method: 'post',
              class: 'icon icon-watcher',
              title: l(:title_easy_printable_templates_generate_docx)
            ) if options[:easy_printable_templates][:project_id].present? && entity.docx_template
          else
            links << link_to(
                l(:button_export),
                easy_xml_easy_printable_templates_export_path(format: :xml, id: entity.id),
                title: l(:button_export),
                method: :post,
                class: 'icon icon-export'
            )
            links << link_to(
              l(:button_edit),
              edit_easy_printable_template_path(entity),
              class: 'icon icon-edit',
              title: l(:button_edit)
            ) if entity.editable?
            links << link_to(
              l(:button_delete),
              easy_printable_template_path(entity),
              method: :delete,
              data: { confirm: l(:text_are_you_sure) },
              class: 'icon icon-del',
              title: l(:button_delete)
            ) if entity.deletable?
          end

          links.html_safe
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyPrintableTemplates::EasyQueryButtonsHelperPatch'
