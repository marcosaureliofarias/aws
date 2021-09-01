module EasyButtons
  class Hooks < Redmine::Hook::ViewListener

    def view_issues_show_description_bottom(context={})
      render_easy_buttons(context, :issue)
    end

    def view_easy_crm_cases_show_journals_top(context={})
      render_easy_buttons(context, :easy_crm_case)
    end

    def render_easy_buttons(context, key)
      context[:hook_caller].send(:render,
        partial: 'easy_buttons/buttons',
        locals: { entity: context[key] }
      )
    end

    def easy_query_writer_filters(context={})
      query = context[:query]

      case query
      when EasyIssueQuery
        if context[:filter] == 'assigned_to_id' && (values = context[:values])
          values.insert(1, ["<< #{l(:label_none)} >>", 'none'])
          values.insert(2, [l(:label_author_assigned_to), 'author'])
          values.insert(3, [l(:label_last_user_assigned_to), 'last_assigned'])
        end
      end

    end

  end
end
