module EasyCrmCountryValuesHelper

  def render_api_easy_crm_country_value(api, easy_crm_country_value)
    api.easy_crm_country_value do
      api.id easy_crm_country_value.id
      api.country easy_crm_country_value.country
      api.created_at easy_crm_country_value.created_at
      api.updated_at easy_crm_country_value.updated_at

      render_api_custom_values easy_crm_country_value.visible_custom_field_values, api

      call_hook(:helper_render_api_easy_crm_country_value, {api: api, easy_crm_country_value: easy_crm_country_value})
    end
  end

end
