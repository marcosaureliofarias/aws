module EasyPatch
  module HTMLFormatting
    module Helper

      def wikitoolbar_for(field_id, preview_url = preview_text_path, options = {})
        heads_for_wiki_formatter

        ck_options = ck_options(field_id, preview_url, options)
        mention_js = "CKEDITOR.config.mentions = [#{ck_mentions(field_id, preview_url, options).join(',')}];"
        reminder_js = ck_reminders(field_id, preview_url, options).join("\n")

        js =
        # language=JavaScript
        "window.enableWarnLeavingUnsaved = '#{User.current.pref.warn_on_leaving_unsaved}';
        EASY.schedule.late(function () {
        EasyGem.loadModules(['easy_ckeditor'],function(ckFactory) {
          #{reminder_js}
          #{mention_js}
          ckFactory('#{field_id}',{#{ck_options.join(',')}});
        })
        });"

        javascript_tag(js)
      end

      def ck_options(field_id, _preview_url = preview_text_path, options = {} )
        custom_settings = options.delete(:custom)
        if in_mobile_view?
          options[:toolbar] = 'Mobile'
        else
          options[:toolbar] ||= EasySetting.value('ckeditor_toolbar_config') || 'Basic'
        end
        options[:lang] ||= User.current.language
        options[:lang] = Setting.default_language if options[:lang].blank?
        options[:language] = options[:lang] if options[:lang].present?

        # Syntax higlight
        if EasySetting.value('ckeditor_syntax_highlight_enabled')
          options[:codeSnippet_theme] ||= EasyCKEditor.syntaxt_higlight_template
        else
          if options[:removePlugins]
            options[:removePlugins] << ','
          else
            options[:removePlugins] = ''
          end

          options[:removePlugins] << 'codesnippet'
        end

        hook_settings = call_hook(:helper_ckeditor_wikitoolbar_for_add_option, { field_id: field_id, options: options })

        ck_options = options.collect { |k, v| "#{k}:'#{v}'" }
        ck_options << 'startupFocus: false'
        ck_options << custom_settings unless custom_settings.blank?
        ck_options << hook_settings unless hook_settings.to_s.blank?
        ck_options
      end

      def ck_mentions(field_id, preview_url = preview_text_path, options = {})
        mentions = []
        call_hook(:helper_ckeditor_mention, { field_id: field_id, options: options, mentions: mentions })
        mentions
      end

      def ck_reminders(field_id, preview_url = preview_text_path, options = {})
        reminders = []

        if options[:attachment_reminder]
          attachment_reminder =
            # language=JavaScript
            "  var $field = $('##{field_id}').addClass('set_attachment_reminder').data({ck: true, attachment_reminder_words: \"#{j(Attachment.attachment_reminder_words)}\", attachment_reminder_confirm: '#{j(l(:text_easy_attachment_reminder_confirm))}'});"
          if options[:attachment_reminder_message]
            attachment_reminder << "  $field.data('attachment_reminder_confirm','#{options[:attachment_reminder_message]}')"
          end
          attachment_reminder << "if(window.EPExtensions){EPExtensions.initAttachmentReminder($field[0])}"
          reminders << attachment_reminder
        end

        call_hook(:helper_ckeditor_reminder, { field_id: field_id, options: options, reminders: reminders })
        reminders
      end

      def initial_page_content(page)
      end

      def heads_for_wiki_formatter
        unless @url_included
          if EasySetting.value('ckeditor_syntax_highlight_enabled')
            content_for :body_bottom, late_javascript_tag(
              # language=JavaScript
              "EasyGem.dynamic.jsTag('#{EasyCKEditor.syntaxt_higlight_js}');
              EasyGem.dynamic.cssTag('#{EasyCKEditor.syntaxt_higlight_css + '.css'}');
              EASY.utils.syntaxHighlight();
            ")
          end
          content_for :header_tags, javascript_tag(
          "EasyGem.module.setUrl('easy_ckeditor','#{asset_path("ckeditor.js")}');")
          @url_included = true
        end
      end
    end
  end
end
