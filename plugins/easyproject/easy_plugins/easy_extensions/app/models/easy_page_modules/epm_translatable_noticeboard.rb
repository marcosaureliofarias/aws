class EpmTranslatableNoticeboard < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def runtime_permissions(user)
    Setting.text_formatting == 'HTML'
  end

  def get_show_data(settings, user, page_context = {})
    data_for_language(settings)
  end

  def get_edit_data(settings, user, page_context = {})
    { wikitoolbar: settings['wikitoolbar'] }
  end

  def page_zone_module_before_save(pzm)
    if pzm.settings[:data].is_a?(String)
      pzm.settings[:data] = JSON.parse(pzm.settings[:data])

      if pzm.settings[:data].is_a? Hash
        pzm.settings[:data] = deep_transform_values(pzm.settings[:data]) do |value|
          Loofah.scrub_fragment(value, :strip).to_s
        end
      end
    end
  end

  def page_module_toggling_container_options_helper_method
    'get_epm_welcome_toggling_container_options'
  end

  def data_for_language(settings, language = nil)
    language ||= User.current.language.to_s
    data     = settings['data'].is_a?(Hash) ? settings['data'] : {}

    if language && (data.dig(language, 'title').present? || data.dig(language, 'content').present?)
      data[language]
    elsif data.dig(I18n.locale.to_s, 'title').present? || data.dig(I18n.locale.to_s, 'content').present?
      data[I18n.locale.to_s]
    elsif data.dig('en', 'title').present? || data.dig('en', 'content').present?
      data['en']
    else
      {}
    end
  end

  private

  def deep_transform_values(hash, &block)
    hash.transform_values do |value|
      value.is_a?(Hash) ? deep_transform_values(value, &block) : yield(value)
    end
  end

end
