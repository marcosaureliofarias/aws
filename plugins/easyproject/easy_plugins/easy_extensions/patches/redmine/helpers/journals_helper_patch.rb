module EasyPatch
  module JournalsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :render_notes, :easy_extensions
        alias_method_chain :journal_thumbnail_attachments, :easy_extensions

        def diff_show_h2(journal)
          case journal.journalized_type
          when 'Issue'
            "#{journal.issue.tracker} ##{journal.issue.id}"
          when 'Project'
            project = Project.find(journal.journalized_id)

            "#{project.name}"
          end
        end

        def diff_show_back_link(journal)
          case journal.journalized_type
          when 'Issue'
            path = issue_path(journal.issue)
          when 'Project'
            project = Project.find(journal.journalized_id)

            path = settings_project_path(project)
          else
            return nil
          end

          link_to(l(:button_back), path, :onclick => 'if (document.referrer != "") {history.back(); return false;}')
        end

        def link_to_in_place_notes_editor(text, field_id, url, options = {})
          onclick = "$.ajax({url: '#{url_for(url)}', type: 'get'}); return false;"
          link_to text, 'javascript:void(0)', options.merge(:onclick => onclick)
        end

        def safe_polymorphic_url(entity)
          polymorphic_url(entity)
        rescue
          nil
        end

      end
    end

    module InstanceMethods

      def journal_thumbnail_attachments_with_easy_extensions(journal)
        entity = journal.journalized
        if entity.respond_to?(:attachments)
          details                   = journal.details.select { |d| ['attachment', 'attachment_version'].include?(d.property) && d.value.present? }
          thumbnailable_attachments = []
          attachment_version        = nil
          details.each do |d|
            if d.property == 'attachment'
              attachment = entity.attachments.detect { |a| a.id == d.prop_key.to_i && a.thumbnailable? }
              if attachment
                attachment_version = attachment.versions.min_by(&:version) || attachment
                thumbnailable_attachments << attachment_version if attachment_version
              end
            elsif d.property == 'attachment_version'
              entity.attachments.each do |a|
                attachment_version = a.versions.detect { |v| v.id == d.prop_key.to_i && a.thumbnailable? }
                break if attachment_version
              end
              thumbnailable_attachments << attachment_version if attachment_version
            end
          end
          thumbnailable_attachments
        else
          []
        end
      end

      def render_notes_with_easy_extensions(entity, journal, options = {})
        content = ''
        project = entity.respond_to?(:project) && entity.project
        links   = []

        if journal.notes.present? && !User.current.in_mobile_view? && !options[:without_menu]
          clipboard_link = proc { |value| link_to(l(:button_link_journal), 'javascript:void(0)',
                                                                       class: 'icon icon-link',
                                                                       onclick: "window.easyUtils.clipboard.copy('#{value}');",
                                                                       title: value) }
          if (url = safe_polymorphic_url(entity))
            links << clipboard_link.call("#{url}/?journals=all#note-#{journal.id}")
          end
          links << link_to(l(:button_quote),
                           { controller: 'journals', action: 'new', id: entity, journal_id: journal },
                           remote: true,
                           method: 'post',
                           title: l(:button_quote),
                           class: 'icon icon-comment') if options[:reply_links]
          links << link_to(l(:button_edit),
                           edit_journal_path(journal),
                           remote: true,
                           method: 'get',
                           title: l(:button_edit),
                           class: 'icon icon-edit'
          ) if journal.editable_by?(User.current)
          links << link_to(l(:button_delete),
                           journal_path(journal, journal: { notes: '' }),
                           remote: true,
                           method: 'put', data: { confirm: l(:text_are_you_sure) },
                           title: l(:button_delete),
                           class: 'icon-only icon-del'
          ) if journal.editable_by?(User.current)

          if journal.private_notes && (User.current.id == journal.user_id || User.current.admin?)
            links << link_to(l(:button_journal_unprivate_note), public_journal_path(journal), method: :post, data: { confirm: l(:text_are_you_sure) }, title: l(:title_journal_unprivate_note), class: 'icon icon-unlock')
          end
          if entity.is_a?(Issue)
            links << link_to(l(:button_create_issue_from_journal), new_issue_path(issue: { project_id: entity.project, description: journal.notes }, subtask_for_id: entity.id), title: l(:title_create_issue_from_journal), class: 'icon icon-add')
          end

          hook_context = { links: links, journal: journal, project: project, entity: entity, options: options }
          call_hook(:helper_journal_render_notes_add_links, hook_context)
          links = hook_context[:links]
        end

        css_classes = 'wiki '
        content << textilizable(journal, :notes) if journal.notes.present?
        css_classes << ' editable' if journal.editable_by?(User.current)
        return_string = ''
        if !User.current.in_mobile_view? && !options[:without_menu]
          return_string << render_menu_more(journal, project, { menu_more_container_class: 'journal-tools hide-when-print', menu_more_class: 'manual-hide', menu_expander_after_function_js: "$(this).toggleClass('open');", menu_expander_class: 'icon icon-settings', label: content_tag(:span, l(:label_user_form_other_settings), class: 'tooltip') }) do
            links.each { |link| concat(content_tag(:li, link)) }
          end
        end
        call_hook(:helper_journal_render_notes_add_content, { journal: journal, content: content, entity: entity })
        return_string << content_tag(:div, content.html_safe, id: "journal-#{journal.id}-notes", class: css_classes) unless content.blank?

        return return_string.html_safe
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'JournalsHelper', 'EasyPatch::JournalsHelperPatch'
