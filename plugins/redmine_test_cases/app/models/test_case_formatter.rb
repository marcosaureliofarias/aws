class TestCaseFormatter < EasyEntityFormatter

  def ending_buttons?
    true
  end

  def format_column(column, entity)
    value = column.value_object(entity)

    case column.name
      when :name
        view.link_to(value, view.test_case_path(entity))
      when :scenario, :expected_result
        view.textilizable(value)
      when :issues
        format_object(value.to_a)
      when :test_plans
        value.to_a.map { |item| view.link_to(item, item) }.join(', ')
    else
        format_object(value)
    end
  end

  def ending_buttons(entity)
    if entity.editable?(User.current)
      view.link_to('', '#', class: 'icon icon-more-horiz btn_contextmenu_trigger', title: l(:title_additional_context_menu))
    else
      ''
    end
  end


end
