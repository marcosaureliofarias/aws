module EasyExtensions
  module EasyTranslator
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_easy_translate(options = {})
        return if self.included_modules.include?(EasyExtensions::EasyTranslator::InstanceMethods) || !EasyTranslation.table_exists?
        cattr_accessor :translater_options
        self.translater_options = {}
        # default column for translate
        columns                           = options.delete(:columns)
        translater_options[:columns]      = columns.blank? ? [:name] : columns.map(&:to_sym)
        translater_options[:default_lang] = options[:default_translation_lang] # :en || :cs

        has_many :easy_translations, as: :entity, dependent: :destroy

        validations = {}
        entity_type = self.to_s
        translater_options[:columns].each do |column|
          self._validators[column].each do |v|
            validations[column] = v.options if v.is_a?(ActiveModel::Validations::LengthValidator)
          end
        end

        if validations.present?
          EasyTranslation.class_eval do
            validations.each do |column, options|
              options      = options.dup
              options[:if] = lambda { self.entity_type == entity_type && self.entity_column.to_sym == column }
              validates_length_of :value, options
            end
          end
        end

        translater_options[:columns].each do |name|

          define_method(name) do |options = {}|
            read_attribute(name, options)
          end
          alias_method :"#{name}_before_type_cast", name

          define_method :"easy_translated_#{name}" do |options = {}|
            read_attribute(name, options)
          end

          define_method :"easy_translated_#{name}=" do |locales_value|
            locales_value.each do |locale, value|
              write_attribute(name, value, { locale: locale })
            end
          end
        end

        send :include, EasyExtensions::EasyTranslator::InstanceMethods

        reflect_on_all_associations(:belongs_to).reject { |a| a.inverse_of.nil? }.each do |association|
          association.klass.send(:define_method, :container_after_save) do
            self.send(association.inverse_of.name).each do |item_class|
              item_class.send(:save_translations)
            end
          end
          association.klass.send(:after_save, :container_after_save, prepend: true)
        end

        after_save :save_translations
        after_initialize -> { @translated_attributes = nil }
      end
    end

    module InstanceMethods
      def self.included(base)
        base.extend ClassMethods
      end

      def read_attribute(attribute, options = {})
        @translated_attributes                   ||= {}.with_indifferent_access
        options                                  = { translated: true, locale: User.current.current_language }.merge(options)
        @translated_attributes[options[:locale]] ||= {}.with_indifferent_access
        if self.class.translater_options[:columns].include?(attribute.to_sym) && (options[:translated] && options[:locale])
          @translated_attributes[options[:locale]][attribute] ||= (read_easy_translated_attribute(attribute, options[:locale]).try(:to_s) || _read_attribute(attribute))
        else
          @translated_attributes[options[:locale]][attribute] = _read_attribute(attribute)
        end
        @translated_attributes[options[:locale]][attribute]
      end

      def write_attribute(attribute, value, options = {})
        @translated_attributes                   = nil
        @translated_attributes                   ||= {}.with_indifferent_access
        options                                  = { locale: User.current.current_language }.merge(options)
        @translated_attributes[options[:locale]] ||= {}.with_indifferent_access
        if !value.blank? && self.class.translater_options[:columns].include?(attribute.to_sym) && options[:locale] && !self.new_record?
          @translation_columns_to_save ||= []
          if !@translation_columns_to_save.detect { |x| x.entity_column == attribute.to_s && x.entity == self && x.lang == options[:locale].to_s }
            @translation_columns_to_save << EasyTranslation.set_translation(self, attribute, value, options[:locale])
          end
        else
          super(attribute, value)
        end
        @translated_attributes[options[:locale]][attribute] = value
      end

      def copy_translations(copy_entity)
        self.easy_translations.each do |translate|
          EasyTranslation.set_translation(copy_entity, translate.entity_column, translate.value, translate.lang)
        end
        copy_entity
      end

      private

      def read_easy_translated_attribute(attribute, lang = nil)
        lang ||= User.current.current_language
        EasyTranslation.get_translation(self, attribute, lang)
      end

      # save translations after entity saved.
      # this is for rollback
      def save_translations
        @translation_columns_to_save && @translation_columns_to_save.map(&:'save!')
      end

      module ClassMethods
      end
    end
  end
end
ActiveRecord::Base.include(EasyExtensions::EasyTranslator)
