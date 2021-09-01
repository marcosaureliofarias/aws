module EasyContacts

  class Hooks < Redmine::Hook::ViewListener

    render_on :view_custom_fields_form_easy_contact_custom_field, :partial => 'custom_fields/easy_contact_form'
    render_on :view_custom_fields_form_easy_contact_group_custom_field, :partial => 'custom_fields/easy_contact_group_form'
    render_on :view_projects_copy, :partial => 'projects/copy_easy_contacts_checkbox'
    render_on :view_issues_show_journals_top, :partial => 'easy_contacts/issue_contacts'
    render_on :view_settings_general_webdav, :partial => 'settings/carddav'
    # render_on :view_layouts_base_body_bottom, :partial => 'easy_contacts/view_layouts_base_body_bottom'
    render_on :view_issues_easy_entity_activity_form_bottom, :partial => 'easy_entity_activities/form_issue_bottom'
    render_on :view_projects_form, :partial => 'projects/form_easy_contact_ids'
    render_on :view_issues_show_api_bottom, partial: 'easy_contacts/issue_related_contacts'
    render_on :view_roles_form_top, partial: 'roles/easy_contacts_visibility'
    render_on :easy_user_type_visibility_options_bottom, partial: 'easy_user_types/visible_contact_types'

    # Hook for add custom_field values to seach results.)
    def helper_easy_extensions_search_helper_patch( context={} )
      entity = context[:entity]
      regexp = /(#{Array(context[:tokens]).map { |t| Regexp.escape(t) }.join('|')})(?!(?:[^<]*?)(?:["'])[^<>]*>)/i
      additional = ''
      if entity.event_type.to_sym == :easy_contact
        additional << content_tag(:span, "<strong>#{entity.class.human_attribute_name(:type)}</strong>".html_safe + ' : ' + entity.type.to_s)

        entity.visible_custom_field_values.each do |custom_value|
          if ((custom_value.value.blank? && custom_value.custom_field.show_empty) || !custom_value.value.blank?)
            additional << content_tag(:span, content_tag(:strong, custom_value.custom_field.translated_name) + ' : ' + (context[:hook_caller].show_value(custom_value) || '-')).html_safe
          end
        end
        attachments = ''
        entity.attachments.each do |a|
          row = link_to_attachment(a, {:download => true})
          row << " - #{a.description}" unless a.description.blank?
          next unless row.match(regexp)
          attachments << content_tag( :li, row)
        end
        unless attachments.blank?
          additional << content_tag( :h4, l(:label_attachment_plural))
          additional << content_tag(:ul, attachments.html_safe, :class => 'attachments')
        end
      end
      context[:additional_result] << content_tag(:p, additional.html_safe, :class => 'contact-detail-container') unless additional.blank?
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_contacts' if enabled_modules && enabled_modules.include?('easy_contacts')
    end

    def model_project_copy_additionals(context={})
      context[:to_be_copied] << 'easy_contacts'
    end

    def view_easy_modal_selector_tag_additional_buttons(context={})
      return if context[:entity_type] != 'EasyContact'
      options = context[:options]
      return if options && options[:hide_create_contact]

      "btns.push({text: '#{j l(:new_contact, :scope => [:easy_contacts_toolbar])}',
        click: function() {$(this).dialog('close');$.get('#{j context[:controller].new_easy_contact_path(:return_to_lookup => options[:return_to_lookup], :format => :js)}')},
        'class': 'button-3 icon icon-add'});"
    end

    def easy_xml_data_import_importer_set_importable(context={})
      unless (easy_contacts_xml = context[:xml].xpath('//easy_xml_data/easy-contacts/*')).blank?
        context[:importables] << EasyXmlData::EasyContactImportable.new(:xml => easy_contacts_xml)
      end
    end

    # def view_easy_modal_selector_link_additional_buttons(context={})
    #   return if context[:entity_type] != 'EasyContact'
    #   options = context[:options]
    #   return if options && options[:hide_create_contact]
    #
    #   "btns.push({text: '#{j l(:button_easy_crm_create_related_contact)}',
    #     click:  function() {$.get('#{j context[:controller].new_easy_contact_path(:format => :js)}')},
    #     'class': 'button-3 icon icon-add'});"
    # end

    def view_easy_printable_templates_token_list_bottom(context = {})
      return if context[:section] != :project
      context[:controller].send :render_to_string,
                                partial: 'easy_printable_templates/easy_contacts_view_easy_printable_templates_token_list_bottom',
                                locals: context
    end

    def helper_ckeditor_mentions_prefixes(context = {})
      context[:prefixes].concat(['easy_contact#'])
    end

    def helper_ckeditor_mention(context = {})
      context[:mentions].concat(
        [
          "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_easy_contacts') + "?query={encodedQuery}"}', marker: 'easy_contact#', pattern: /easy_contact#\\d*$/,
           itemTemplate: '<li data-id=\"{id}\">\#{id}: {subject}</li>' }"
        ]
      )
    end
  end
end
