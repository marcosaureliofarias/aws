require 'sanitize'

module EasyKnowledge
  class EasyKnowledgeHooks < Redmine::Hook::ViewListener

    render_on :view_projects_copy, :partial => 'projects/copy_checkbox'
    render_on :view_project_destroy_confirmations, :partial => 'projects/kb_destroy_confirmation'
    render_on :view_issues_show_journals_top, :partial => 'issues/easy_knowledge_stories'

    def view_layouts_base_body_bottom(context={})
      s = ''
      if !context[:controller].in_mobile_view? && EasyKnowledgeBase.toolbar_enabled?
        s << context[:controller].send(:render_to_string, :partial => 'easy_knowledge/toolbar_actions', :locals => context).html_safe
      end

      s.html_safe
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_knowledge' if enabled_modules && enabled_modules.include?('easy_knowledge')
    end

    def model_project_copy_additionals(context={})
      context[:to_be_copied] << 'easy_knowledge'
    end

    def view_issue_sidebar_issue_buttons(context={})
      issue = context[:issue]
      context[:controller].send(:render_to_string, {:locals => context}.merge(:partial => 'easy_knowledge_stories/mark_as_story_sidebar_buttons', :locals => { :new_story => { :entity_type => 'Issue', :entity_id => issue.id, :name => issue.subject }}))
    end

    def helper_journal_render_notes_add_links(context={})
      return unless (issue = context[:entity]).is_a?(Issue)
      if context[:project].module_enabled?(:easy_knowledge)
        link = context[:hook_caller].easy_knowledge_new_story_button(issue, 'Journal', context[:journal].id, issue.subject)
        context[:links] << link if link
      end
    end

    def view_easy_printable_templates_token_list_bottom(context = {})
      return if context[:section] != :plugins
      context[:controller].send :render_to_string,
                                partial: 'easy_printable_templates/easy_knowledge_view_easy_printable_templates_token_list_bottom',
                                locals: context
    end

    def easy_extensions_javascripts_hook(context={})
      context[:template].require_asset('easy_knowledge_application')
    end

    def helper_ckeditor_mentions_prefixes(context = {})
      context[:prefixes].concat(['easy_knowledge_story#'])
    end

    def helper_ckeditor_mention(context = {})
      context[:mentions].concat(
        [
          "{ feed: '#{context[:hook_caller].easy_autocomplete_path('ckeditor_easy_knowledge_stories') + "?query={encodedQuery}"}', marker: 'easy_knowledge_story#', pattern: /easy_knowledge_story#\\d*$/,
           itemTemplate: '<li data-id=\"{id}\">\#{id}: {subject}</li>' }"
        ]
      )
    end

  end
end

