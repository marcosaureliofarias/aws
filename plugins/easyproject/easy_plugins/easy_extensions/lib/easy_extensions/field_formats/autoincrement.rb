module EasyExtensions
  module FieldFormats

    class Autoincrement < Redmine::FieldFormat::IntFormat
      add 'autoincrement'

      self.form_partial         = 'custom_fields/formats/autoincrement'
      self.summable_supported   = false
      self.searchable_supported = true

      def label
        :label_autoincrement
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        if options[:default_value].blank? && custom_value.autoincrement_number_valid?
          value = custom_value.value
        else
          value = CustomValue.get_next_autoincrement(custom_value.custom_field, custom_value.customized).to_s
        end

        view.text_field_tag(tag_name, value, { :id => tag_id }.merge(options))
      end

    end

  end
end
