module EasyPatch
  module FormBuilderPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        include Redmine::I18n

        alias_method_chain :text_field, :easy_extensions
        alias_method_chain :text_area, :easy_extensions

        def decorate_translater_field(method, options = {})
          obj_class = @object.class
          if obj_class.respond_to?(:translater_options) && obj_class.translater_options[:columns].include?(method.to_sym) && !@object.new_record?
            # locale = options[:locale] || User.current.current_language
            options[:class] ||= ''
            field_value     = @object.send(method).to_s
            link            = @template.link_to("", @template.easy_translations_path(obj_class.name, @object, method), remote: true, class: "easy-translation-link icon icon-edit", title: l(:button_edit))

            @template.content_tag(:span, @template.content_tag(:input, nil, class: 'easy-translator-input-field', value: field_value, disabled: true, type: 'text') + link, class: 'input-append')
          else
            yield(method, options)
          end
        end

      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def text_field_with_easy_extensions(method, options = {})
        decorate_translater_field(method, options) { |method, options| text_field_without_easy_extensions(method, options) }
      end

      def text_area_with_easy_extensions(method, options = {})
        decorate_translater_field(method, options) { |method, options| text_area_without_easy_extensions(method, options) }
      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'ActionView::Helpers::FormBuilder', 'EasyPatch::FormBuilderPatch'
