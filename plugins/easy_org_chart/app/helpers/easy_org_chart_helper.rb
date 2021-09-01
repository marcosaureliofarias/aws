module EasyOrgChartHelper
  def easy_org_chart_setting(name, namespace = nil)
    value = nil

    if @easy_page_zone_module
      settings = namespace ? @easy_page_zone_module.settings[namespace] || {} : @easy_page_zone_module.settings
      value = settings[name]
    end

    if value.nil?
      value = namespace ? EasySetting.value(:easy_org_chart_show_custom_fields)[name] : EasySetting.value("easy_org_chart_#{name}")
    end

    value.to_boolean
  end

  def easy_org_chart_display_field_value(value, field_name)
    return if value.blank?

    if easy_org_chart_setting(:show_fields_names)
      [content_tag(:b, field_name.to_s.strip), value].join(": ")
    else
      value
    end
  end

  def easy_org_chart_user_data(user)
    data = {id: user.to_gid_param, name: user.name, user_id: user.id}

    data[:avatar] = avatar_url(user).presence || "/plugin_assets/easy_extensions/images/avatar.jpg"

    data[:custom_fields] = []
    if easy_org_chart_setting(:show_email)
      data[:custom_fields] << easy_org_chart_display_field_value(user.mail, l(:label_email))
    end

    if easy_org_chart_setting(:show_user_type) && user.easy_user_type
      data[:custom_fields] << easy_org_chart_display_field_value(user.easy_user_type.name, l(:label_easy_user_type))
    end

    @easy_org_chart_user_cf_list ||= UserCustomField.all

    @easy_org_chart_user_cf_list.each do |user_cf|
      if easy_org_chart_setting(user_cf.id.to_s, :show_custom_fields)
        data[:custom_fields] << easy_org_chart_display_field_value(user.custom_field_value(user_cf), user_cf.name)
      end
    end

    data[:custom_fields].delete_if(&:blank?)

    data
  end

  def build_hierarchy(api, scope)
    tree = EasyOrgChart::Tree.new(scope)
    if tree.root&.user
      build_user_node api, tree.root
    end
  end

  def build_user_node(api, node)
    build_user_data api, easy_org_chart_user_data(node.user)
    if node.children.any?
      api.array :children do
        node.children.each do |child|
          next unless child.user
          api.user do
            build_user_node api, child
          end
        end
      end
    end
  end

  def build_user_data(api, data)
    data.each_pair do |key, value|
      api.__send__ key, value
    end
  end
end
