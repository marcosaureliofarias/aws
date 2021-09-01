class TestCaseIssueExecutionFormatter < EasyEntityFormatter

  def ending_buttons?
    true
  end

  def format_column(column, entity)
    value = column.value_object(entity)

    case column.name
      when :test_case
        view.link_to(value, value)
      when :test_plans
        value.to_a.map { |item| view.link_to(item, item) }.join(', ')
      when :test_case_issue_execution_result
        unless value.nil?
          (value.name == 'Pass' ? view.content_tag(:i, '', class: 'icon-true') : view.content_tag(:i, '', class: 'icon-false')) + value.name
        end
      else
        format_object(value)
    end
  end

  def ending_buttons(entity)
    if entity.editable?
      issue = view.instance_variable_get(:'@issue') || view.instance_variable_get(:'@source_entity')
      view.link_to(l(:button_show), view.test_case_issue_execution_path(entity), class: 'icon icon-detail', title: l(:button_show), remote: true).html_safe+
      view.link_to(l(:button_edit), view.edit_test_case_issue_execution_path(entity, back_url: issue ? view.issue_path(issue) : nil), class: 'icon icon-edit', title: l(:button_edit), remote: true).html_safe +
      view.link_to(l(:button_delete), view.test_case_issue_execution_path(entity, back_url: issue ? view.issue_path(issue) : nil), method: 'DELETE', data: {confirm: l(:text_are_you_sure), remote: true}, class: 'icon icon-del', title: l(:button_delete)).html_safe
    else
      ''
    end
  end


end
