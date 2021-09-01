module EasyContacts
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_contact_query_additional_ending_buttons(contact, options={})
          s = ''
          s << link_to(content_tag(:span, l(:button_show), :class => 'tooltip'), @project ? project_easy_contact_path(@project, contact) : easy_contact_path(contact), :class => 'icon icon-magnifier', :title => l(:button_show))
          call_hook(:helper_easy_contact_query_ending_buttons, {:contact => contact, :content => s})
          if contact.editable?
            s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), {:controller => 'easy_contacts', :action => 'edit', :id => contact, :project_id => @project}, :class => 'icon icon-edit', :title => l(:button_edit))
          end
          if contact.principal_assignement
            s << link_to(content_tag(:span, l(:button_remove_from_me), :class => 'tooltip'), remove_from_entity_easy_contact_path(contact, {:entity_type => 'User', :entity_id => User.current, :back_url => easy_contacts_path(:project_id => @project)}), :method => :delete, :class => 'icon icon-remove', :title => l(:button_delete))
          end

          if contact.project_assignement
            s << link_to(content_tag(:span, l(:button_remove_from_project), :class => 'tooltip'), remove_from_entity_project_easy_contact_path(@project, contact, {:entity_id => @project, :entity_type => @project.class.name, :back_url => project_easy_contacts_path(@project)}), :method => :delete, :class => 'icon icon-remove', :title => l(:button_delete))
          end

          l = link_to_google_map(contact.address)
          s << l if l

          return s.html_safe
        end

        def easy_contact_group_query_additional_ending_buttons(group, options={})
          s = ''
          s << link_to( l(:button_show), {:controller => 'easy_contact_groups', :action => 'show', :id => group, :project_id => @project}, :class => 'icon icon-group', :title => l(:button_show))
          s << link_to( l(:button_edit), {:controller => 'easy_contact_groups', :action => 'edit', :id => group, :project_id => @project}, :class => 'icon icon-edit', :title => l(:button_edit))

          return s.html_safe
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyContacts::EasyQueryButtonsHelperPatch'
