module EasyExtensions
  module FieldFormats

    class CountrySelect < Redmine::FieldFormat::ListFormat
      add 'country_select'

      self.form_partial         = nil
      self.type_for_inline_edit = 'select'

      def label
        :label_country_select
      end

      def validate_custom_value(custom_value)
        values         = Array.wrap(custom_value.value).reject(&:blank?)
        invalid_values = values -
            Array.wrap(custom_value.value_was) - ISO3166::Country.codes
        if invalid_values.any?
          [::I18n.t('activerecord.errors.messages.inclusion')]
        else
          []
        end
      end

      def validate_custom_field(custom_field)
        []
      end

      def cast_single_value(custom_field, value, customized = nil)
        ISO3166::Country[value].try(:translation, ::I18n.locale.to_s[0..1])
      end

      def possible_custom_value_options(custom_value)
        options = ISO3166::Country.all_names_with_codes(::I18n.locale.to_s)
        return options if custom_value.value.blank?
        missing = Array(custom_value.value) - ISO3166::Country.codes
        options += missing.map { |v| [v.to_s, v.to_s] } if missing.any?
        options
      end

    end
  end
end
