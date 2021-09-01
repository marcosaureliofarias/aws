Redmine::MenuManager.map :easy_crm_case_sidebar_more_menu do |menu|
  menu.push :new_project, :link_to_easy_crm_case_new_template,
            caption: :label_template_new,
            html: {
                class: 'button icon icon-add',
                title: EasyExtensions::MenuManagerProc.new{ I18n.t(:label_template_new) }
            },
            if: -> easy_crm_case { Project.allowed_to_create_project_from_template? }

  menu.push :move, :link_to_easy_crm_case_move,
            caption: :button_move,
            html: {
                class: 'button icon icon-move',
                title: EasyExtensions::MenuManagerProc.new{ I18n.t(:sidebar_crm_case_button_move) }
            },
            if: -> easy_crm_case { easy_crm_case.editable? }

  menu.push :delete, :easy_crm_case_path,
            caption: :button_delete,
            html: {
              class: 'icon icon-del button',
              id: 'issue-sidebar-link_to-delete',
              method: :delete,
              title: EasyExtensions::MenuManagerProc.new{ I18n.t(:title_easy_crm_case_delete) },
              'data-confirm' => EasyExtensions::MenuManagerProc.new{
                I18n.t(:text_issues_destroy_confirmation)
              }
            },
            if: -> easy_crm_case { easy_crm_case.deletable? }

  menu.push :add_related_task, :add_or_create_related_issue_easy_crm_case_path,
            caption: :button_easy_crm_add_or_create_related_issue,
            html: {
                class: 'icon icon-add button',
                title: EasyExtensions::MenuManagerProc.new{ I18n.t(:button_easy_crm_add_or_create_related_issue) },
                data: {remote: true}
            }

  menu.push :add_related_contact, :add_or_create_related_easy_contact_easy_crm_case_path,
            caption: :button_easy_crm_add_or_create_related_contact,
            html: {
                class: 'icon icon-add button',
                title: EasyExtensions::MenuManagerProc.new{ I18n.t(:button_easy_crm_add_or_create_related_contact) },
                data: {remote: true}
            }

  menu.push :merge, 'javascript:EASY.utils.showAndScrollTo("merge_to_form", -150, "merge_to_container");',
            caption: :button_merge,
            html: {
                class: 'button icon icon-integrate',
                title: EasyExtensions::MenuManagerProc.new{ I18n.t(:button_merge_to) },
            },
            if: -> easy_crm_case { User.current.allowed_to?(:edit_easy_crm_cases, easy_crm_case.project) }

  menu.push :sales_activities, { controller: :easy_crm_cases, action: :sales_activities },
            param: -> easy_crm_case { { set_filter: '1', 'easy_crm_cases.name': easy_crm_case.name } },
            caption: :button_easy_crm_view_sales_activities,
            html: {
                class: 'icon icon-list button'
            },
            if: -> easy_crm_case { EasySetting.value('show_easy_entity_activity_on_crm_case', easy_crm_case.project) }
end
