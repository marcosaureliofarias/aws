module EasyCustomFieldPermissions
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_custom_fields_form_right_content, partial: 'easy_custom_field_permissions/view_custom_fields_permissions_form'
  end
end
