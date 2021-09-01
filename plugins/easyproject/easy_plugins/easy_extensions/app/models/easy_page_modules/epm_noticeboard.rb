class EpmNoticeboard < EasyPageModule

  TRANSLATABLE_KEYS = [
      %w[heading]
  ]

  def category_name
    @category_name ||= 'others'
  end

  def get_edit_data(settings, user, page_context = {})
    wikitoolbar = settings["wikitoolbar"]
    return { :wikitoolbar => wikitoolbar }
  end

  def page_zone_module_before_save(epzm)
    if Setting.text_formatting == 'HTML' && epzm.settings['text'].present?
      epzm.settings['text'] = Loofah.scrub_fragment(epzm.settings['text'], :strip).to_s
    end
  end

end
