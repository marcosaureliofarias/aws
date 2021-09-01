module EasyExtensions
  module FieldFormats

    class Email < Redmine::FieldFormat::StringFormat
      add 'email'

      self.form_partial = 'custom_fields/formats/email'

      def label
        :label_email
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        html ? view.mail_to(value) : value.to_s
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        view.text_field_tag(tag_name, custom_value.value, options.merge(:id => tag_id))
      end

    end

  end
end
