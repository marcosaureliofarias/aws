module EasyHelpdesk
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_helpdesk_project_query_additional_ending_buttons(entity, options = {})
          s = ''
          s << link_to(content_tag(:span,l(:button_edit),:class => 'tooltip'), edit_easy_helpdesk_project_path(entity), :class => 'icon icon-edit', :title => l(:button_edit))
          s << link_to(content_tag(:span,l(:button_delete),:class => 'tooltip'), easy_helpdesk_project_path(entity), :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del', :title => l(:button_delete))
          s.html_safe
        end

        def easy_sla_event_query_additional_ending_buttons(easy_sla_event, options={})
          s = ''
          back_url ||= easy_sla_events_path
          if easy_sla_event.deletable?
            s << link_to(l(:button_delete), project_easy_sla_event_path(easy_sla_event.project_id, easy_sla_event.id, back_url: back_url), method: :delete, data: { confirm: l(:text_are_you_sure) }, class: 'icon icon-del')
          end
          s.html_safe
        end
      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyHelpdesk::EasyQueryButtonsHelperPatch'
