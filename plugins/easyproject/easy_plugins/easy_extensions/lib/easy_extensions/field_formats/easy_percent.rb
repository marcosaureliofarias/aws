module EasyExtensions
  module FieldFormats

    class Percent < Redmine::FieldFormat::FloatFormat
      include EasyExtensions::EasyAttributeFormatter

      add 'easy_percent'

      self.field_attributes :easy_percent
      self.form_partial       = 'custom_fields/formats/easy_percent'
      self.summable_supported = false
      self.numeric            = true

      def label
        :label_percent
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        return '' unless value
        locale_val = format_locale_number(value.to_f, strip_insignificant_zeros: true)
        html ? "#{locale_val} %" : locale_val
      end

      def validate_single_value(custom_field, value, customized = nil)
        errs  = super
        value = value.to_s
        if custom_field.easy_min_value && value.to_f < custom_field.easy_min_value
          errs << ::I18n.t('activerecord.errors.messages.greater_than_or_equal_to', :count => custom_field.easy_min_value)
        end
        if custom_field.easy_max_value && custom_field.easy_max_value > 0 && value.to_f > custom_field.easy_max_value
          errs << ::I18n.t('activerecord.errors.messages.less_than_or_equal_to', :count => custom_field.easy_max_value)
        end
        errs
      end

      def query_filter_options(custom_field, query)
        { :type => :float }
      end

    end

  end
end
