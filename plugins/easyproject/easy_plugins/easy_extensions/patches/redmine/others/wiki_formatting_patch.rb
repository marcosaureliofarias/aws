module EasyPatch
  module WikiFormattingPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :wikitoolbar_for, :easy_extensions

        def current_language
          l('jquery.locale', :default => ::I18n.locale.to_s)
        end

      end

    end

    module InstanceMethods

      def wikitoolbar_for_with_easy_extensions(field_id, preview_url = preview_text_path, options = {})
        wiki_toolbar = wikitoolbar_for_without_easy_extensions(field_id, preview_url)
        return '' if wiki_toolbar.nil?

        reminder_confirm = options[:attachment_reminder_message] ? options[:attachment_reminder_message] : l(:text_easy_attachment_reminder_confirm)
        reminderjs       = options[:attachment_reminder] ? "$('##{field_id}').addClass('set_attachment_reminder').data('ck', false).data('reminder_words', \"#{j(Attachment.attachment_reminder_words)}\").data('reminder_confirm', '#{j(reminder_confirm)}'); " : ''
        wiki_toolbar + late_javascript_tag(reminderjs)
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_other_patch ['Redmine::WikiFormatting::NullFormatter::Helper', 'Redmine::WikiFormatting::Textile::Helper', 'Redmine::WikiFormatting::Markdown::Helper'], 'EasyPatch::WikiFormattingPatch'
