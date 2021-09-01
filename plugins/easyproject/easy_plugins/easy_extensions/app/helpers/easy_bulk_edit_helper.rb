module EasyBulkEditHelper

  def easy_bulk_options_for_select(options, selected = nil)
    options_for_select([[l(:label_no_change_option), '']] + options, selected.to_s)
  end

  def easy_bulk_boolean_options(selected = nil)
    content_tag('option', l(:label_no_change_option), :selected => (selected.to_s == ''), :value => '') +
        content_tag('option', l(:general_text_Yes), :selected => (selected.to_s == '1' || selected == true), :value => '1') +
        content_tag('option', l(:general_text_No), :selected => (selected.to_s == '0' || selected == false), :value => '0')
  end

  def easy_bulk_boolean_select_tag(field_name, selected = '', options = {})
    select_tag(field_name, easy_bulk_boolean_options(selected), options)
  end

  def easy_bulk_modal_selector_field_tag(entity_type, entity_attribute, field_name, field_id, selected_values = {}, options = {})

    selected_values = { '__no_change__' => l(:label_no_change_option) }

    easy_modal_selector_field_tag(entity_type, entity_attribute, field_name, field_id, selected_values, options)
  end

end
