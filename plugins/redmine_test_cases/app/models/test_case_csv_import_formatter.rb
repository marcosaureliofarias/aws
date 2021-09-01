class TestCaseCsvImportFormatter < EasyEntityFormatter

  def ending_buttons?
    true
  end

  def ending_buttons(entity)
    if entity.editable?(User.current)
      # issue = view.instance_variable_get(:'@issue') || view.instance_variable_get(:'@source_entity')
      view.link_to(l(:button_view), view.test_cases_csv_import_path(entity), class: 'icon icon-edit', title: l(:button_edit)).html_safe +
      view.link_to(l(:button_edit), view.edit_test_cases_csv_import_path(entity), class: 'icon icon-edit', title: l(:button_edit)).html_safe +
      view.link_to(l(:button_delete), view.test_cases_csv_import_path(entity), method: 'DELETE', data: {confirm: l(:text_are_you_sure), remote: true}, class: 'icon icon-del', title: l(:button_delete)).html_safe
    else
      ''
    end
  end


end