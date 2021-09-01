module EasyPrintableTemplates
  class Hooks < Redmine::Hook::ViewListener

    def easy_calculation_exports_bottom(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)
      context[:controller].send(:render_to_string, :partial => 'easy_calculation/pdf_export', :locals => context)
    end

    def view_easy_qr_bottom(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)
      context[:controller].send(:render_to_string, :partial => 'easy_qr/easy_printable_templates_view_easy_qr_bottom', :locals => context)
    end

    def view_roles_form_top(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)
      context[:controller].send(:render_to_string, :partial => 'roles/easy_printable_templates_visibility', :locals => context)
    end

    def view_issues_context_menu_end(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)

      back_url = context[:back]
      project = context[:project]
      entity_type = 'EasyIssueQuery'
      selected_ids = context[:ids]

      context[:controller].send(:render_to_string, :partial => 'context_menus/easy_printable_templates_view_context_menu_end', :locals => {:back_url => back_url, :project => project, :entity_type => entity_type, :entity_id => nil, :selected_ids => selected_ids}) if selected_ids.count == 1
    end

    def view_issue_other_formats_link_bottom(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)

      f = context[:f]
      issue = context[:issue]

      return context[:f].link_to 'Print', {:caption => l(:button_print), :title => l(:button_print), :url => {:controller => 'easy_printable_templates', :action => 'template_chooser', :format => nil, :entity_type => 'Issue', :entity_id => issue.id, :back_url => context[:controller].issue_path(issue)}, :remote => true, :add_query_params => 'entity_settings'}
    end

    def view_easy_invoices_context_menu_end(context={})
      return unless User.current.allowed_to_globally?(:view_easy_printable_templates)

      back_url = context[:back]
      project = context[:project]
      selected_ids = EasyInvoice.non_templates.where(:id => context[:ids]).pluck(:id)
      if selected_ids.count==1
        entity_type = 'EasyInvoice'
        entity_id = selected_ids.first
      else
        entity_type = 'EasyInvoiceQuery'
        entity_id = nil
        project = nil
      end

      if selected_ids.any?
        context[:controller].send(:render_to_string, :partial => 'context_menus/easy_printable_templates_view_context_menu_end', :locals => {:back_url => back_url, :project => project, :entity_type => entity_type, :entity_id => entity_id, :selected_ids => selected_ids})
      end
    end

    def easy_xml_data_import_importer_set_importable(context = {})
      if (easy_printable_templates_xml = context[:xml].xpath('//easy_xml_data/easy-printable-templates/*')).present?
        context[:importables] << EasyXmlData::EasyPrintableTemplateImportable.new(xml: easy_printable_templates_xml)
      end

      if (easy_printable_template_pages_xml = context[:xml].xpath('//easy_xml_data/easy-printable-template-pages/*')).present?
        context[:importables] << EasyXmlData::EasyPrintableTemplatePageImportable.new(xml: easy_printable_template_pages_xml)
      end
    end

  end
end
