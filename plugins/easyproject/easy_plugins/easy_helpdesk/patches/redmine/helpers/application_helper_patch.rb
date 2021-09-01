module EasyHelpdesk
  module ApplicationHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def render_easy_entity_card_easy_helpdesk_project(easy_helpdesk_project, source_entity, options = {})
          easy_entity_card(easy_helpdesk_project, source_entity, options) do |eec|
            eec.link_to_entity link_to_project(easy_helpdesk_project.project)
            eec.avatar avatar(easy_helpdesk_project.project.author, :style => :medium, :no_link => true)
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_project_detail', :layout => false, :formats => [:html], :locals => {:project => easy_helpdesk_project.project, :options => options})
            eec.footer_left content_tag(:span, easy_helpdesk_project.tag_list.map{|t| link_to(t, easy_tag_path(t))} .join(', ').html_safe, :class => 'entity-array') if !easy_helpdesk_project.tag_list.blank?
          end
        end

        def easy_helpdesk_mail_template_options_for_select(issue, selected_template = nil)
          mail_template_options = EasyHelpdeskMailTemplate.find_all_for_issue(issue)
          options_for_select(mail_template_options.collect{|t| [t.name, t.id]}, selected_template&.id)
        end
      end
    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyHelpdesk::ApplicationHelperPatch'
