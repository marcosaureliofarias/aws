class EpmCalculoid < ::EasyPageModule

  def category_name
    @category_name ||= 'others'
  end
  
  def runtime_permissions(user)
    Rys::Feature.active?('easy_calculoid') && user.allowed_to_globally?(:view_easy_calculoid)
  end
  
  def get_show_data(settings, user, page_context = {})
    data = settings['data'] || {}
    trends = (settings['trends'] || {})
    trend_modules = EasyPageZoneModule.where(uuid: trends.values).group_by(&:uuid)
    trends.each do |k, v|
      if v.present? && trend_modules.has_key?(v)
        show_data = trend_modules[v].first.get_show_data(user, nil, page_context) || {}
        if show_data[:number_to_show].present?
          data[k] = show_data[:number_to_show].to_s
        end
      end
    end
    { data: data }
  end
  
end
