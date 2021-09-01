module EasyPatch
  module FormTagHelperPatch

    def self.included(base)
      base.include InstanceMethods
      base.class_eval do

        alias_method_chain :label_tag, :easy_extensions

        def easy_html5_date_tag(name, value = nil, options = {})
          tag :input, { 'type' => 'date', 'name' => name, 'id' => sanitize_to_id(name), 'value' => value }.update(options.stringify_keys)
        end

        def easy_html5_datetime_tag(name, value = nil, options = {})
          tag :input, { 'type' => 'datetime', 'name' => name, 'id' => sanitize_to_id(name), 'value' => value }.update(options.stringify_keys)
        end
      end
    end

    module InstanceMethods
      def label_tag_with_easy_extensions name = nil, content_or_options = nil, options = nil, &block
        if block_given? && content_or_options.is_a?(Hash)
          options = content_or_options = content_or_options.stringify_keys
        else
          options ||= {}
          options = options.stringify_keys
        end

        if options.delete('required').to_boolean
          content = content_or_options.is_a?(String) ? content_or_options : name.to_s.humanize
          content = content + ' *'
          options['class'] = "#{options['class']} required"
          label_tag_without_easy_extensions name, content, options, &block
        else
          label_tag_without_easy_extensions name, content_or_options, options, &block
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::FormTagHelper', 'EasyPatch::FormTagHelperPatch'
