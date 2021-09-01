# this module is intended to be included in EasyPageZoneModule and EasyPageTemplateModule
# it translates values in settings which are saved under translatable_keys
# values are translated to values saved in settings under key translations
# if you want to see original settings you have to set @do_not_translate to true
module EasyPageModules
  module TranslatableSettings

    # return [Array] of keys which should be translated
    # @example [[name], [query, name]]
    def translatable_keys
      module_definition ? module_definition.class.translatable_keys : []
    end

    def do_not_translate=(value)
      @do_not_translate = value
    end

    # @example Buries a value into the given hash
    #   deep_set({}, my_value, :a, :b, :c) => { a: { b: c: my_value } }
    def deep_set(hash, value, *keys)
      keys[0...-1].inject(hash) { |acc, h| acc[h] ||= {} }[keys.last] = value
    end

    # @return [String, nil] Returns translated value or nil for given keys
    def get_translation_for(*keys, settings: nil)
      settings ||= read_attribute('settings')
      return unless (translations = settings['translations']).is_a?(Hash)

      locales_order.each do |locale|
        if (value = translations.dig(*keys, locale).presence)
          return value
        end
      end

      nil
    end

    # @note Order in which translated value is searched
    def locales_order
      [User.current.language.to_s.presence, I18n.locale.to_s.presence, 'en'].compact
    end

    # @return [String, nil] returns untranslated value for given keys
    # @note for [key1, key2] it returns value saved under [key1, _key2]
    def get_original_value_for(*keys)
      untranslated_keys = keys.deep_dup
      untranslated_keys.last.prepend('_')

      settings.dig(*untranslated_keys)
    end

    # @return [Hash] with locale as key and translated value as value
    def translations_for_keys(*keys)
      translation_hash = settings['translations'] || {}
      translation_hash.dig(*keys)&.dup || {}
    end

    def write_attribute(*args)
      @do_not_translate = true if args[0].to_s == 'settings'
      super
    end

    # @return [Hash] settings with translated values and untranslated values under keys with underscore
    def settings(_options = {})
      translated_settings = super()
      return translated_settings if @do_not_translate

      translatable_keys.each do |keys|
        unless @default_values_set
          untranslated_keys = keys.deep_dup
          untranslated_keys.last.prepend('_')
          untranslated_value = translated_settings.dig(*keys)
          deep_set(translated_settings, untranslated_value, *untranslated_keys) if untranslated_value
        end

        next unless translated_value = get_translation_for(*keys, settings: translated_settings)

        deep_set(translated_settings, translated_value, *keys)
      end

      @default_values_set = true
      translated_settings
    end

  end
end
