module EasyChecklistPlugin
  module EasyJournalHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :show_easy_journal_detail, :easy_checklist
      end
    end

    module InstanceMethods

      def show_easy_journal_detail_with_easy_checklist(detail, no_html=false, options={})
        if %w(easy_checklist easy_checklist_item).include?(detail.property)
          value ||= detail.value
          old_value ||= detail.old_value
          name = detail.prop_key
          label = l("label_#{detail.property}_journal_detail", name: name.to_s)
          multiple = true

          if !detail.value.blank?
            if detail.old_value.present?
              l(:text_journal_changed, label: label, old: old_value, new: value).html_safe
            elsif multiple
              l(:text_journal_added, label: label, value: value).html_safe
            else
              l(:text_journal_set_to, label: label, value: value).html_safe
            end
          else
            l(:text_journal_deleted, label: label, old: old_value).html_safe
          end
        else
          show_easy_journal_detail_without_easy_checklist(detail, no_html, options)
        end
      end

    end

    module ClassMethods
    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'EasyJournalHelper', 'EasyChecklistPlugin::EasyJournalHelperPatch', if: proc { Redmine::Plugin.installed?(:easy_extensions) }
