module TestCasesHelper

  def render_api_test_case(api, test_case)
    api.test_case do
      api.id test_case.id
      api.name test_case.name
      api.scenario test_case.scenario
      api.project_id test_case.project_id
      api.author_id test_case.author_id
      api.created_at test_case.created_at
      api.updated_at test_case.updated_at
      render_api_custom_values test_case.visible_custom_field_values, api
      api.array :attachments do
        test_case.attachments.each do |attachment|
          render_api_attachment(attachment, api)
        end
      end if include_in_api_response?('attachments')

      call_hook(:helper_render_api_test_case, {api: api, test_case: test_case})
    end
  end

  def test_case_render_half_width_custom_fields_rows(issue, except: [])
    values = issue.visible_custom_field_values.reject {|value| value.custom_field.full_width_layout? || except.include?(value.custom_field.internal_name)}
    return if values.empty?
    half = (values.size / 2.0).ceil
    issue_fields_rows do |rows|
      values.each_with_index do |value, i|
        css = "cf_#{value.custom_field.id}"
        attr_value = show_value(value)
        if value.custom_field.text_formatting == 'full'
          attr_value = content_tag('div', attr_value, class: 'wiki')
        end
        m = (i < half ? :left : :right)
        rows.send m, custom_field_name_tag(value.custom_field), attr_value, :class => css
      end
    end
  end


  end
