module EasyContactTypesHelper

  def render_api_easy_contact_type(api, easy_contact_type)
    api.easy_contact_type do
      api.id(easy_contact_type.id)
      api.type_name(easy_contact_type.type_name)
      api.required_lastname(easy_contact_type.personal?)
      api.position(easy_contact_type.position)
      api.is_default(easy_contact_type.is_default)
      api.icon_path(easy_contact_type.icon_path)
      api.internal_name(easy_contact_type.internal_name)
    end
  end

end
