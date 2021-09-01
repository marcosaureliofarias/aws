module EasyCrm
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_easy_rake_tasks_receive_mail_before_type_settings, :partial => 'easy_rake_tasks/settings/easy_crm_view_easy_rake_tasks_receive_mail_before_type_settings'
    render_on :easy_view_issues_new_form, :partial => 'issues/easy_crm_issues_new_form'
    render_on :view_easy_contacts_form_top, :partial => 'easy_contacts/easy_crm_easy_contacts_form_top'
    render_on :view_issues_show_journals_top, :partial => 'issues/easy_crm_cases'
    render_on :view_custom_fields_form_easy_crm_case_custom_field, :partial => 'custom_fields/easy_crm_case_form'
    render_on :view_easy_invoices_show_sidebar, :partial => 'easy_invoices/easy_crm_invoice_sidebar'
    render_on :view_search_index_advance_options_bottom, :partial => 'search/easy_crm_case_search_options'
    render_on :view_easy_crm_case_item_edit_before_total_price, :partial => 'easy_crm_case_items/easy_crm_case_item_discount'
    render_on :view_easy_contacts_sidebar_buttons, :partial => 'easy_contacts/easy_crm_easy_contacts_sidebar_buttons'
    render_on :view_issue_sidebar_issue_buttons, partial: 'issues/easy_crm_case_related_issue_sidebar'
    render_on :view_roles_form_top, partial: 'roles/easy_crm_cases_visibility'
    render_on :view_easy_money_sidebar_links_bottom, partial: 'easy_money/sidebar_entities_link'
    render_on :easy_contacts_toolbar_assignable_entities_bottom, partial: 'easy_contacts_toolbar/register_easy_crm_case'

    def helper_easy_extensions_search_helper_patch( context={} )
      return unless context[:entity].event_type == 'easy-crm-case'
      context[:additional_result] << context[:controller].send(:render_to_string, :partial => 'search/easy_crm_case_result_formating', locals: context)
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_crm' if enabled_modules && enabled_modules.include?('easy_crm')
    end

    def helper_project_settings_tabs(context={})
      project = context[:project]
      template = context[:controller].params[:template]
      partial = template ? template : 'projects/settings/easy_crm_settings'
      context[:tabs] << {:name => 'easy_crm', :url => context[:controller].easy_crm_settings_project_path(project), :partial => partial, :label => :label_easy_crm, :redirect_link => true} if project.module_enabled?(:easy_crm)
    end

    def view_easy_external_emails_preview_external_email(context={})
      return unless context[:entity].is_a?(EasyCrmCase)
      context[:controller].send(:render_to_string, :partial => 'easy_external_emails/easy_crm_preview_external_email', :locals => context)
    end

    def view_easy_contacts_after_create_js(context={})
      view_context = context[:controller].view_context
      s = view_context.easy_modal_selector_field_tag('EasyContact', 'link_with_name', 'easy_crm_case[main_easy_contact_id]', 'easy_crm_case_easy_contact_ids', EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(context[:easy_contact], display_name: Proc.new { |easy_contact| view_context.link_to_easy_contact(easy_contact) }), url: {}, multiple: false)

      "$('#easy_crm_case_easy_contact_ids_container').html('#{j s}')"
    end

    def controller_issues_new_after_save(context={})
      if (easy_crm_case_id = context[:params][:easy_crm_case_id]) && (easy_crm_case = EasyCrmCase.find_by(id: easy_crm_case_id))
        if User.current.allowed_to?(:edit_easy_crm_cases, easy_crm_case.project)
          begin
            easy_crm_case.issues << context[:issue]
          rescue
          end
        end
      end
    end

    def controller_easy_contacts_after_save(context={})
      if (easy_crm_case_id = context[:params][:easy_crm_case_id]) && (easy_crm_case = EasyCrmCase.find_by(id: easy_crm_case_id))
        if User.current.allowed_to?(:edit_easy_crm_cases, easy_crm_case.project)
          begin
            easy_crm_case.easy_contacts << context[:easy_contact]
          rescue
          end
        end
      end
    end

    def link_to_easy_money_overview_entity(context={})
      entity = context[:entity]
      entity_type = context[:entity_type]
      project = context[:project]
      label = context[:label]

      case entity_type
      when 'EasyCrmCase'
        link_to(label, context[:controller].project_easy_crm_case_path(project, entity), :title => label, :class => 'button icon icon-money')
      end
    end

    def easy_invoicing_invoice_details_bottom(context={})
      f = context[:f]
      invoice = context[:invoice]
      f.hidden_field(:easy_crm_case_id, :value => invoice.easy_crm_case.id) if invoice.easy_crm_case
    end

    def helper_ckeditor_mentions_prefixes(context = {})
      context[:prefixes].concat(['easy_crm_case#'])
    end

    def helper_ckeditor_mention(context = {})
      context[:mentions].concat(
        [
          "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_easy_crm_cases') + "?query={encodedQuery}"}', marker: 'easy_crm_case#', pattern: /easy_crm_case#\\d*$/,
           itemTemplate: '<li data-id=\"{id}\">\#{id}: {subject}</li>' }"
        ]
      )
    end

    def model_project_send_all_planned_emails(context={})
      return if !Setting.notified_events.include?('easy_crm_case_added')

      project = context[:project]

      return if !project.module_enabled?(:easy_crm)

      project.easy_crm_cases.active.each do |easy_crm_case|
        EasyCrmMailer.deliver_easy_crm_case_added(easy_crm_case)
      end
    end

    def model_project_create_sql_where(context={})
      if context[:compute_childs]
        context[:sql_where] << "EXISTS (
SELECT c.id
FROM #{EasyCrmCase.table_name} c
INNER JOIN #{Project.table_name} p ON p.id = c.project_id
WHERE c.id = #{context[:entity_table_name]}.entity_id
AND #{context[:entity_table_name]}.entity_type = 'EasyCrmCase' AND p.lft >= #{context[:entity].lft} AND p.rgt <= #{context[:entity].rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      else
        context[:sql_where] << "EXISTS (
SELECT c.id
FROM #{EasyCrmCase.table_name} c
INNER JOIN #{Project.table_name} p ON p.id = c.project_id
WHERE c.id = #{context[:entity_table_name]}.entity_id
AND #{context[:entity_table_name]}.entity_type = 'EasyCrmCase' AND p.id = #{context[:entity].id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      end
    end

    def helper_users_easy_lesser_admin_permissions(context = {})
      context[:list] << [l(:label_easy_crm), :easy_crm]
    end
  end
end
