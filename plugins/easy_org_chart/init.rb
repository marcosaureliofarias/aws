Redmine::Plugin.register :easy_org_chart do
  name :easy_org_chart_plugin_name
  author :easy_org_chart_plugin_author
  author_url :easy_org_chart_plugin_author_url
  description :easy_org_chart_plugin_description
  version '2018'
  requires_redmine_plugin :easy_extensions, version_or_higher: '2018'

  #into easy_settings goes available setting as a symbol key, default value as a value
  settings partial: 'easy_org_chart',
           only_easy: true,
           easy_settings: {
               node_width: '200',
               root_node_background_color: '#007aad',
               parent_node_background_color: '#dbd1c7',
               node_background_color: '#f9f6a8',
               show_avatar: true,
               show_email: false,
               show_user_type: false,
               show_fields_names: false,
               show_custom_fields: {},
               share_subordinates_access: 'forbidden'
           }

end
