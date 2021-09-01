module EasyExtensions
  class EasyLabelledFormBuilder < ActionView::Helpers::FormBuilder
    include Redmine::I18n
    include EasyIconsHelper

    (field_helpers.map(&:to_s) - %w[radio_button hidden_field fields_for check_box label] +
        %w[date_select]).each do |selector|
      src = <<-END_SRC
      def #{selector}(field, options = {})
        label_for_field(field, options) + super(field, options.except(:label)).html_safe
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
      box = super(field, options.except(:label, :class), checked_value, unchecked_value).html_safe
      return box if options.delete(:no_label)

      options[:class] ||= ''
      options[:class] << ' checkbox inline'
      label_for_field(field, options.except(:onchange).merge(input: box))
    end

    def select(field, choices, options = {}, html_options = {})
      label_for_field(field, options) + super(field, choices, options, html_options.except(:label)).html_safe
    end

    def time_zone_select(field, priority_zones = nil, options = {}, html_options = {})
      label_for_field(field, options) + super(field, priority_zones, options, html_options.except(:label)).html_safe
    end

    def text_field(field, options = {})
      label = label_for_field(field, options.except(:append))
      if options.key?(:append)
        append = options.delete(:append)
        input  = @template.content_tag(:span, super(field, options) + append, class: 'input-append')
      else
        input = super(field, options)
      end
      (label + input).html_safe
    end

    def label_for_field(field, options = {})
      return ''.html_safe if options.delete(:no_label)

      text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
      text ||= @object.class.human_attribute_name(field) if @object && @object.class.respond_to?(:human_attribute_name)
      text ||= l(('field_' << field.to_s.gsub(/_id$/, '')).to_sym)

      input = ''

      additional_classes = []
      additional_classes << 'error' if @object.try(:errors) && @object.errors[field].present?

      if options.delete(:required)
        text += @template.content_tag(:span, ' *', class: 'required')
        additional_classes << 'required'
      end

      if options.key?(:class)
        additional_classes << options.delete(:class)
      end

      if options.key?(:input)
        input << options.delete(:input)
      end

      if options.key?(:additional_for)
        options[:for] = [@object_name.to_s, options.delete(:additional_for).to_s, field.to_s].join('_')
      end

      options[:class] = [options[:class], additional_classes].join(' ')

      label(field, options.except(:id)) do
        input.html_safe + text.html_safe
      end
    end

    def easy_icon_select(field, options = {})
      label_for_field(field, options) +
          easy_icon_select_tag("#{object_name}[#{field}]", @object.try(field), options.except(:label))
    end

    def auto_complete(field, source, options = {})
      select_options                      = { id: "#{object_name}_#{field}", select_first_value: false, multiple: false }.merge(options.except(:label))

      name = "#{object_name}[#{field}]"
      name << '[]' if select_options[:multiple]

      value = options[:selected] || safe_field_value(field)
      label_for_field(field, options) + @template.autocomplete_field_tag(name, source, Array(value), select_options)
    end

    def easy_combo_box(field, source, options = {})
      auto_complete(field, source, options.merge(combo: true))
    end

    def calendar(field, options = {})
      text_field(field, options.merge(size: 10)) + @template.calendar_for("#{object_name}_#{field}")
    end

    private

    # proxy
    def easy_autocomplete_tag(name, selected_value, source, options = {})
      @template.easy_autocomplete_tag(name, selected_value, source, options)
    end

    def safe_field_value(field)
      # Because of `FormModel` is using `method_missing`
      # IDEA: Or maybe object.easy_proxy?
      if object.is_a?(EasySettings::FormModel)
        object.send(field)
      else
        object.try(field)
      end
    end

  end
end
