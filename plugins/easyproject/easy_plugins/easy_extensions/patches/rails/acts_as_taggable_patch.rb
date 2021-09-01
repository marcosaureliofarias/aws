module EasyPatch
  module ActsAsTaggablePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :acts_as_taggable_on, :easy_extensions

      end
    end

    module InstanceMethods

      def acts_as_taggable_on_with_easy_extensions(*tag_types)
        options = {}

        if tag_types.last.is_a?(Hash)
          options     = tag_types.pop
          plugin_name = options[:plugin_name]
          return false if !plugin_name.nil? && !Redmine::Plugin.installed?(plugin_name)
        end

        EasyExtensions::EasyTag.register(self, options)

        acts_as_taggable_on_without_easy_extensions(*tag_types)
      end

    end

  end
end
EasyExtensions::PatchManager.register_patch_to_be_first 'ActsAsTaggableOn::Taggable', 'EasyPatch::ActsAsTaggablePatch', :first => true
