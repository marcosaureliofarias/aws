module EasyProjectAttachments
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_documents_bottom, :partial => 'easy_project_attachments/easy_query', :locals => {:easy_query_label => ''}

    def easy_controller_documents_index(context={})
      project = context[:project]
      if project && User.current.allowed_to?(:view_easy_project_attachments, project)
        query = context[:controller].retrieve_query(EasyProjectAttachmentQuery)
        context[:controller].instance_variable_set(:@query, query)
        context[:controller].sort_init(query.sort_criteria_init)
        context[:controller].sort_update(query.sortable_columns)
        context[:controller].send(:prepare_easy_query_render)
        context[:controller].send(:render_easy_query_html)
      end
    end

  end
end
