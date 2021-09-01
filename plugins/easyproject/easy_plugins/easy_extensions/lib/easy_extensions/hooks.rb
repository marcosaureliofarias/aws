module EasyExtensions
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_users_form, :partial => 'users/additional_fields'
    render_on :view_easy_page_templates_index_additional_actions, :partial => 'easy_page_templates/template_actions'
    render_on :view_my_account_contextual, :partial => 'my/avatar'
    render_on :view_layouts_base_body_bottom, :partial => 'layouts/layouts_base_body_bottom'
    render_on :view_my_account_mail_signature, :partial => 'users/easy_extensions_view_easy_mail_signature'
    render_on :view_account_login_top, :partial => 'account/unsupported_browser'

    include EasyIconsHelper

    def controller_enumerations_create_after_save(context = {})
      enumeration_after_save(context)
    end

    def controller_enumerations_edit_after_save(context = {})
      enumeration_after_save(context)
    end

    def controller_easy_page_layout_layout_from_template_to_all(context = {})
      page_template, page, actions = context[:page_template], context[:page], context[:actions]

      if actions.include?('projects') && page.page_name == 'project-overview'
        Project.non_templates.sorted.pluck(:id).each do |project_id|
          EasyPageZoneModule.create_from_page_template(page_template, nil, project_id)
        end
      end
    end

    def controller_projects_create_after_save(context = {})
      project = context[:project]
      if context[:params][:project] && context[:params][:project][:inherit_time_entry_activities].to_s.to_boolean
        project.inherit_time_entry_activities = true
        project.copy_time_entry_activities_from_parent
      end
      if EasyPage.table_exists? && EasyPageTemplate.table_exists? && EasyPageZoneModule.table_exists?
        page          = EasyPage.where(:page_name => 'project-overview').first
        page_template = page.default_template

        EasyPageZoneModule.create_from_page_template(page_template, nil, project.id)
      end
    end

    def controller_projects_new(context = {})
      context[:project].inherit_time_entry_activities = true unless context[:params][:project]
      context[:project].inherit_members               = !!EasySetting.value('default_project_inherit_members') unless context[:params][:project]
    end

    def controller_timelog_edit_before_save(context = {})
      time_entry, params = context[:time_entry], context[:params]

      if params[:new_project_id]
        time_entry.project = Project.find(params[:new_project_id])
      end
    end

    def controller_account_success_authentication_after(context = {})
      user = context[:user]
      if user.change_password_allowed? && (days = user.show_passwd_expiration_notification)
        link                                 = link_to(l(:button_change_password), { controller: 'password', action: 'password', back_url: context[:controller].home_path }, remote: true, class: 'icon icon-passwd')
        context[:controller].flash[:warning] = l(:notice_password_expiration, days: days, link: link).html_safe
      end
    end

    def view_easy_gantt_index_sidebar(**context)
      if context[:query] && context[:query].is_a?(EasyQuery)
        context[:controller].send(:render_to_string,
                                  partial: 'sidebar/saved_easyqueries_by_type',
                                  locals:  {
                                      query_class: context[:query].class,
                                      query_link:  { controller: 'easy_gantt', action: 'index', gantt_type: context[:gantt_type] },
                                      project:     context[:project]
                                  }
        )
      end
    end

    def view_easy_rake_tasks_after_submit(context = {})
      task = context[:task]
      return unless task.is_a?(EasyRakeTaskReceiveMail)
      context[:controller].send(:render_to_string, :partial => 'easy_rake_tasks/settings/easy_extensions_view_easy_rake_tasks_after_submit', :locals => context)
    end

    def view_enumerations_form_bottom(context = {})
      enumeration = context[:enumeration]

      case enumeration
      when DocumentCategory
        context[:controller].send(:render_to_string, :partial => 'documents/additional_category_form', :locals => context, :enumeration => enumeration).html_safe
      when TimeEntryActivity
        s = ''
        s << context[:controller].send(:render_to_string, :partial => 'enumerations/easy_extensions_view_enumerations_form_bottom', :locals => context).html_safe
        s << choose_color_scheme(:enumeration, enumeration)
        s
      when IssuePriority, EasyProjectPriority
        choose_color_scheme(:enumeration, enumeration)
      when EasyEntityActivityCategory
        choose_icon(context)
      end
    end

    def view_issue_statuses_form(context = {})
      issue_status = context[:issue_status]
      choose_color_scheme(:issue_status, issue_status)
    end

    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      return unless issue.easy_is_repeating? && issue.easy_next_start
      context[:controller].send(:render_to_string, :partial => 'issues/easy_repeating_view_issues_show_details_bottom', :locals => context)
    end

    def view_projects_form(context = {})
      f       = context[:form]
      project = context[:project]
      if project.safe_attribute?('inherit_time_entry_activities')
        content_tag(:p, f.check_box(:inherit_time_entry_activities), :class => 'inheritance-option')
      end
    end

    def view_templates_create_project_from_template(context = {})
      if context[:template_params].nil? || context[:template_params][:default_settings]
        checked = true
      elsif context[:template_params].present?
        checked = context[:template_params][:inherit_time_entry_activities] == '1'
      end

      html = label_tag('template[inherit_time_entry_activities]', l(:field_inherit_time_entry_activities))
      html << check_box_tag('template[inherit_time_entry_activities]', '1', checked)
      content_tag(:p, html, :class => 'inheritance-option')
    end

    def helper_ckeditor_mentions_prefixes(context = {})
      if context[:options] && context[:options][:hook_caller].assigns['issue']
        context[:prefixes] << 'attachment:'
      end
    end

    def helper_ckeditor_mention(context = {})
      context[:mentions].concat(prefix_config(context))

      if (entity = context[:hook_caller].assigns['issue'])
        context[:mentions] << "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_attachments',
                                                                                       entity_id: entity.id, entity_type: entity.class.to_s) + "&query={encodedQuery}"}', marker: 'attachment:', pattern: /attachment:\\w*$/,
           itemTemplate: '<li data-id=\"{id}\">{name}: {subject}</li>', outputTemplate: 'attachment:\"{subject}\"' }"
      end

      context[:mentions].concat(
          [
              "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_users') + "?query={encodedQuery}"}', marker: '@', pattern: /@[a-z0-9_\\-@\\.]*$/,
           itemTemplate: '<li data-id=\"{id}\">{name}: {full_name} <img class=\"gravatar\" src=\"{avatar}\" width=32 heigh=32></img></li>' }",
              "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_issues') + "?query={encodedQuery}"}', marker: '#', pattern: /#\\d*$/,
           itemTemplate: '<li data-id=\"{id}\">\#{id}: {subject}</li>' }"
          ]
      )
    end

    private

    def prefix_by_marker(context)
      EasyCKEditor.mentions_prefixes(context).inject({}) do |acc, p|
        marker      = p.slice!(0, 2)
        acc[marker] ||= []
        acc[marker] << p
        acc
      end
    end

    def prefix_config(context)
      prefix_by_marker(context).map do |key, values|
        values = values.to_json
        "{ feed: #{values}, pattern: /#{key}\\w*$/, marker: '#{key}', itemTemplate: '<li data-id=\"{id}\">{name}</li>', outputTemplate: '{name}' }"
      end
    end

    def enumeration_after_save(context = {})
      enumeration, params = context[:enumeration], context[:controller].params
      return unless enumeration.respond_to?(:easy_permissions)

      if params['easy_permission']
        if params['easy_permission']['read']
          ep           = enumeration.easy_permissions.detect { |x| x.name == 'read' } || enumeration.easy_permissions.new(:name => 'read')
          ep.role_list = params['easy_permission']['read']['custom_roles'] == '0' ? [] : (params['easy_permission']['read']['role_list'] || []).collect(&:to_i)
          ep.save!
        end

        if params['easy_permission']['manage']
          ep           = enumeration.easy_permissions.detect { |x| x.name == 'manage' } || enumeration.easy_permissions.new(:name => 'manage')
          ep.role_list = params['easy_permission']['manage']['custom_roles'] == '0' ? [] : (params['easy_permission']['manage']['role_list'] || []).collect(&:to_i)
          ep.save!
        end
      end
    end

    def choose_color_scheme(name, entity)
      s = Array.new

      s << label_tag("#{name}_easy_color_scheme", l(:label_easy_color_schemes)) + easy_color_scheme_select_tag("#{name}[easy_color_scheme]", :selected => entity.easy_color_scheme, :class => entity.easy_color_scheme)
      if EasySetting.value('issue_color_scheme_for') != entity.class.name.underscore
        s << '<span class="help-block text-center">'
        s << l(:easy_color_scheme_not_available, :current => l("label_#{EasySetting.value('issue_color_scheme_for')}_plural"))
        s << link_to(l(:label_my_page_issue_query_new_link), { :controller => 'settings', :tab => 'issues' })
        s << '</span>'
      end

      content_tag(:p, s.join("\n").html_safe)
    end

    def choose_icon(context)
      content_tag(:p, easy_icon_select_tag('enumeration[easy_icon]', context[:f].object.easy_icon, :label => l(:field_easy_icon)))
    end

  end
end
