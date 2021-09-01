class DiagramFormatter < EasyEntityFormatter

  def ending_buttons?
    true
  end

  def format_column(column, entity)
    value = column.value_object(entity)

    case column.name
    when :title
      back_url = view.diagrams_path

      view.link_to(value, view.diagram_path(entity, back_url: back_url))
    else
      format_object(value)
    end
  end

  def ending_buttons(entity)
    if entity.editable?(User.current)
      back_url = view.diagrams_path

      view.link_to(l(:button_show), view.diagram_path(entity), remote: true, class: 'icon icon-eye', title: l(:button_show)).html_safe +
      view.link_to(l(:button_edit), view.diagram_path(entity, back_url: back_url), class: 'icon icon-edit', title: l(:button_edit)).html_safe +
      view.link_to(l(:button_delete), view.diagram_path(entity, back_url: back_url), method: :delete, data: { confirm: l(:text_are_you_sure) }, class: 'icon icon-del', title: l(:button_delete)).html_safe
    end
  end
end
