class EasyTranslation < ActiveRecord::Base
  belongs_to :entity, polymorphic: true

  validates :value, :entity_column, :lang, presence: true

  after_save :expire_cache
  after_destroy :expire_cache

  # Find translation for entity + column.
  # Search in user translation and EN for default
  def self.get_translation(entity, column, lang = nil)
    lang = lang.to_s

    Rails.cache.fetch "#{entity.class.base_class.name}/#{entity.id}/#{column}/#{lang}" do
      translation_scoped = entity.easy_translations.where(entity_column: column)

      if (default_lang = entity.class.translater_options[:default_lang])
        translation_scoped = translation_scoped.where(lang: [lang, default_lang]).to_a

        (translation_scoped.detect { |i| i.lang == lang } || translation_scoped.first)&.value
      else
        translation_scoped.where(lang: lang).limit(1).pluck(:value).first
      end

    end
  end

  def self.set_translation(entity, column, value, lang = nil)
    lang ||= User.current.current_language
    if entity.is_a?(Hash)
      entity = entity[:entity_type].camelcase.constantize.find(entity[:entity_id])
    end

    translation       = entity.easy_translations.where(entity_column: column, lang: lang).first
    translation       ||= entity.easy_translations.build(entity_column: column, lang: lang)
    translation.value = value
    Rails.cache.delete("#{entity.class.base_class.name}/#{entity.id}/#{column}/#{lang}")
    translation
  end

  def to_s
    value.to_s
  end

  private

  def expire_cache
    Rails.cache.delete("#{entity_type}/#{entity_id}/#{entity_column}/#{lang}")
  end
end
