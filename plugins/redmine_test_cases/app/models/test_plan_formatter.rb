class TestPlanFormatter < EasyEntityFormatter

  def ending_buttons?
    true
  end

  def format_column(column, entity)
    value = column.value_object(entity)

    case column.name
      when :name
        view.link_to(value, view.polymorphic_path([entity.project, entity]))
      when :test_cases
        format_object(value.to_a)
    else
        format_object(value)
    end
  end

  def ending_buttons(entity)
    if entity.editable?(User.current)
      view.link_to(l(:button_edit), view.edit_polymorphic_path([entity.project, entity]), class: 'icon icon-edit', title: l(:button_edit)).html_safe +
      view.link_to(l(:button_delete), view.polymorphic_path([entity.project, entity]), method: 'DELETE', data: {confirm: l(:text_are_you_sure)}, class: 'icon icon-del', title: l(:button_delete)).html_safe
    else
      ''
    end
  end


end
