module EasyChecklistPlugin
  class Hooks < Redmine::Hook::ViewListener

    #render_on :view_issues_show_description_bottom, :partial => 'easy_checklists/easy_checklists'

    # for redmine
    #render_on :view_issues_form_details_bottom, :partial => 'issues/easy_checklist_form'
    # for easyredmine
    render_on :view_issues_static_issue_attributes_under_attachments, :partial => 'issues/easy_checklist_form'
    render_on :new_easy_crm_case_form_bottom, :partial => 'issues/easy_checklist_form'
    render_on :view_new_issue_module_form_bottom, :partial => 'easy_checklists/easy_checklist_form_bottom', :locals => {:options => {:include_cocoon => true}}

    #render_on :view_easy_crm_case_show_description_bottom, :partial => 'easy_checklists/easy_checklists'

    def model_issue_copy_from(context={})
      new_issue = context[:copy]
      original_issue = context[:copied_from]
      project = new_issue.project

      return if !project.module_enabled?(:easy_checklists)
      return if !original_issue.easy_checklists.exists?

      original_issue.easy_checklists.each do |easy_checklist|
        new_checklist = easy_checklist.dup
        new_checklist.easy_checklist_items = []
        easy_checklist.easy_checklist_items.each do |easy_checklist_item|
          new_checklist.easy_checklist_items << easy_checklist_item.dup
        end
        new_issue.easy_checklists << new_checklist
      end
    end

    def view_issues_show_description_bottom(context={})
      project = context[:project]
      if display_easy_checklist?(project)
        options = {:partial => 'easy_checklists/easy_checklists'}
        context[:hook_caller].send(:render, {:locals => context.merge(:entity => context[:issue])}.merge(options))
      end
    end

    def view_easy_crm_case_entity_cards_top(context={})
      project = context[:project]
      if display_easy_checklist?(project)
        options = {:partial => 'easy_checklists/easy_checklists'}
        context[:hook_caller].send(:render, {:locals => context.merge(:entity => context[:easy_crm_case])}.merge(options))
      end
    end

    def easy_view_issues_new_form(context={})
      context[:hook_caller].send(:content_for, :header_tags, context[:hook_caller].send(:easy_cocoon_tags))
    end

    def view_issues_form_details_bottom(context={})
      project = context[:project]
      issue = context[:issue]
      if issue && issue.new_record? && !(context[:request] && context[:request].params[:copy_from]) && display_easy_checklist?(project)
        options = {:partial => 'issues/easy_checklist_form'}
        context[:hook_caller].send(:render, {:locals => context.merge(:entity => issue)}.merge(options))
      end
    end

    def new_easy_crm_case_form_bottom(context={})
      project = context[:project]
      easy_crm_case = context[:easy_crm_case]
      if display_easy_checklist?(project)
        options = {:partial => 'issues/easy_checklist_form'}
        context[:entity] = easy_crm_case
        context[:hook_caller].send(:render, {:locals => context}.merge(options))
      end
    end

    def display_easy_checklist?(project)
      project && project.module_enabled?(:easy_checklists) && User.current.allowed_to?(:view_easy_checklists, project)
    end

    def helper_project_settings_tabs(context={})
      project = context[:project]
      context[:tabs] << {:name => 'easy_checklist', :action => :manage_easy_checklist_templates, :partial => 'projects/settings/easy_checklist', :label => :label_easy_checklist, :no_js_link => true} if project.module_enabled?(:easy_checklists)
    end

    def model_project_copy_additionals(context={})
      project = context[:source_project]
      context[:to_be_copied] << 'easy_checklists' if project.module_enabled?('easy_checklists')
    end

  end
end
