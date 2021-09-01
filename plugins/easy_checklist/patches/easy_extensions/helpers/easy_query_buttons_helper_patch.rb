module EasyChecklistPlugin
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_checklist_query_additional_ending_buttons(entity, options = {})
          s = ''

          s << link_to(l(:button_edit), edit_easy_checklist_path(entity), :class => 'icon icon-edit', :title => l(:button_edit)) if entity.can_edit?
          s << link_to(l(:button_delete), easy_checklist_path(entity), :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del', :title => l(:button_delete)) if entity.can_delete?

          s.html_safe
        end

      end
    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyChecklistPlugin::EasyQueryButtonsHelperPatch', if: proc { Redmine::Plugin.installed?(:easy_extensions) }
