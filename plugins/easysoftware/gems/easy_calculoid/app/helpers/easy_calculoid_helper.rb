module EasyCalculoidHelper
  def include_calculoid_tags(settings)
    unless @calculoid_included
      content_for :body_bottom do
        controller.render_to_string(partial: 'easy_calculoid/include_tags', locals: {settings: settings})
      end
      @calculoid_included = true
    end
  end

  def valid_uri?(value)
    begin
      uri = URI.parse(value)
      uri.kind_of?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end
  end

  def trend_options(page_module)
    return unless page_module.is_a?(EasyPageZoneModule)
    trend_module = EpmTrends.first
    return unless trend_module
    am = EasyPageAvailableModule.where(easy_pages_id: page_module.easy_pages_id, easy_page_modules_id: trend_module.id).first
    epzms = EasyPageZoneModule.includes(:page_tab).where(user_id: page_module.user_id, entity_id: page_module.entity_id, easy_page_available_modules_id: am.id,
      easy_pages_id: page_module.easy_pages_id).order(Arel.sql("easy_page_user_tabs.position ASC"))

    epzms.inject({}) do |acc, t|
      tab = t.page_tab&.name
      acc[tab] ||= []
      name = t['settings']['name']
      name += " (#{t['settings']['description']})" if t['settings']['description'].present?
      acc[tab] << [name, t.uuid]
      acc
    end
  end
end