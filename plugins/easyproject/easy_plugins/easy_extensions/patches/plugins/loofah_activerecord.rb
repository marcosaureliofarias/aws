module EasyPatch
  module LoofahActiveRecordExtensionPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :html_fragment, :easy_extensions
      end
    end

    module InstanceMethods

      # condition (Setting.text_formatting == 'HTML') must be inside before validation
      #    if will be outside = condition is executed only once (when rails is starting)
      #    and validation will not be affected when editor change
      def html_fragment_with_easy_extensions(attr, options = {})
        raise ArgumentError, 'html_fragment requires :scrub option' unless method = options[:scrub]
        before_validation(if: options[:if]) do |record|
          if Setting.text_formatting == 'HTML' || options[:force]
            record[attr] = Loofah.scrub_fragment(record[attr], method).to_s if record[attr].to_s.present?
          end
        end

        # html_fragment_without_easy_extensions(attr, options)
      end

    end

  end
end

EasyExtensions::PatchManager.register_redmine_plugin_patch 'Loofah::ActiveRecordExtension', 'EasyPatch::LoofahActiveRecordExtensionPatch'
