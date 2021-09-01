module EasyPrintableTemplatesHelper

  def easy_printable_template_pages_orientation
    [[EasyPrintableTemplate.translate_pages_orientation(EasyPrintableTemplate::PAGES_ORIENTATION_PORTRAIT), EasyPrintableTemplate::PAGES_ORIENTATION_PORTRAIT], [EasyPrintableTemplate.translate_pages_orientation(EasyPrintableTemplate::PAGES_ORIENTATION_LANDSCAPE), EasyPrintableTemplate::PAGES_ORIENTATION_LANDSCAPE]]
  end

  def easy_printable_template_pages_size
    [['A2', 'a2'], ['A3', 'a3'], ['A4', 'a4'], ['Custom', 'custom']]
  end

  def easy_printable_template_link_to_add_token(text, form, field_text)
    editor_id = convert_form_name_to_id(form.object_name + '[page_text]')

    js = ''
    if Setting.text_formatting == 'HTML'
      js = "CKEDITOR.instances['#{editor_id}'].insertText(text);"
    else
      js = "$('##{editor_id}').val($('##{editor_id}').val() + text);"
    end
    js << '$("#ajax-modal").dialog("close");'

    link_to_function(text, js, :title => l(:title_easy_printable_templates_add_token, :token => field_text))
  end

end
