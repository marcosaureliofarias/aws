module EasyExtensions
  module FieldFormats

    class Amount < Redmine::FieldFormat::FloatFormat
      add 'amount'

      self.field_attributes :amount_type
      self.form_partial = 'custom_fields/formats/amount'

      def label
        :label_amount
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        options = { :no_html => !html, :precision => custom_field.precision, :strip_insignificant_zeros => custom_field.strip_insignificant_zeros }
        view.format_price(cast_single_value(custom_field, value, customized), custom_field.amount_type.to_s, options)
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        "<span class='amount-cf-wrapper'>#{super(view, tag_id, tag_name, custom_value, options)}<span class='amount-type-currency'>#{custom_value.custom_field.amount_type.to_s}</span></span>".html_safe
      end

    end

  end
end
