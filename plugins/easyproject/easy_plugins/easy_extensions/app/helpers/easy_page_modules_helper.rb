module EasyPageModulesHelper

  def epm_easy_queries(page_module, query_class, project = nil)
    user = (page_module.is_a?(EasyPageZoneModule) && page_module.user) ? page_module.user : User.current

    easy_queries = query_class.sorted.where(:type => query_class.name) # without subclasses
    if page_module.is_a?(EasyPageZoneModule)
      return easy_queries.visible(user)
    elsif page_module.is_a?(EasyPageTemplateModule)
      return easy_queries.where(:easy_queries => { :visibility => [EasyQuery::VISIBILITY_PUBLIC, EasyQuery::VISIBILITY_ROLES] }).sorted
    else
      raise ArgumentError, 'The page_module has to be EasyPageZoneModule or EasyPageTemplateModule.'
    end
  end

  # *modul_uniq_id* => Uniq page module id
  # *url* => url_for action where is previewepc
  # *update* => HTML element which is updated after complete ajax
  # *label* => label of button
  def adhoc_preview_button(modul_uniq_id, options)
    label           = options.delete(:label) || l(:label_preview)
    options[:class] = "button-positive icon icon-checked apply-link #{options[:class]}"
    options[:data]  = {
        :url            => options.delete(:url) || preview_easy_queries_path,
        :target         => options.delete(:update),
        :module_uniq_id => modul_uniq_id,
        :query_class    => options.delete(:query)
    }

    return link_to(label, 'javascript:void(0)', { :onclick => 'EASY.query.applyPreviewEasyQueryInModules(this)' }.merge(options))
  end


  def controller_for_module(page_module)
    case page_module
    when EasyPageZoneModule
      'easy_page_layout'
    when EasyPageTemplateModule
      'easy_page_template_layout'
    end
  end

  def group_load_url_for_module(page_module, query)
    settings_from_params = params.to_unsafe_hash[page_module.module_name.to_sym] || {}
    { controller: controller_for_module(page_module), action: 'get_group_entities', page_module_id: page_module.id, project_id: query.project, original_url: original_url, query: query.to_params.merge(settings_from_params.symbolize_keys).except(:chart_settings) }
  end

  def easy_page_module_sort_link(page_module, query, column, caption, default_order)
    css, order = nil, default_order

    if column.to_s == query.sort_helper.first_key
      if query.sort_helper.first_asc?
        css   = 'sort asc'
        order = 'desc'
      else
        css   = 'sort desc'
        order = 'asc'
      end
    end
    caption = column.to_s.humanize unless caption

    sort_options = { :sort => query.sort_helper.add(column.to_s, order).to_param }

    link_to(caption, update_my_page_module_view_path(page_module.id, { page_module.module_name => sort_options, :template => page_module.is_a?(EasyPageTemplateModule) ? '1' : '0', :project_id => query.project }), { :remote => true, :class => css })
  end

  def easy_page_module_sort_header_tag(page_module, query, column, options = {})
    caption         = options.delete(:caption) || column.to_s.humanize
    default_order   = options.delete(:default_order) || 'asc'
    options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]
    if query.sort_helper || query.set_sort_helper
      content_tag('th', easy_page_module_sort_link(page_module, query, column, caption, default_order), options)
    else
      content_tag('th', caption, options)
    end
  end

  def add_tab_to_back_url
    [:back_url, :back_url2].each do |param|
      change_url_params!(params[param]) do |p|
        p['t'] = params[:t]
      end if params[param]
    end if params[:t]
    true
  end

end
