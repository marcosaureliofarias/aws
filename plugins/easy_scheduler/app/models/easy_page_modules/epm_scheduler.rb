class EpmScheduler < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, _user, _page_context = {})
    add_additional_filters_from_global_filters!(_page_context, settings)
    
    preparation = EasyScheduler::Preparation.new(settings)

    if page_zone_module
      page_zone_module.css_class = 'easy-page__module--scheduler'
    end
    {
      query: preparation.query,
      scheduler_settings: preparation.scheduler_settings,
      tagged_queries: preparation.tagged_queries
    }
  end

  def get_edit_data(settings, _user, _page_context = {})
    preparation = EasyScheduler::Preparation.new(settings)
    {
      query: preparation.query,
      selected_principal_options: preparation.selected_principal_options,
      icalendars: preparation.icalendars
    }
  end

  def before_from_params(page_zone_module, params)
    if EasyScheduler.easy_calendar? && (params && params[:scheduler_settings])
      params[:scheduler_settings][:icalendars] = params.dig(:scheduler_settings, :icalendars) || []
    end
  end
  
  def self.async_load
    false
  end

  def self.show_placeholder
    false
  end

end
