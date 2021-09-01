module EasyPatch
  module AssetUrlHelperPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :asset_path, :easy_extensions
      end
    end

    module InstanceMethods
      def asset_path_with_easy_extensions(source, options = {})
        skip_pipeline = (/.*\?\d+$/.match?(source))
        asset_path_without_easy_extensions(source, options.merge(skip_pipeline: skip_pipeline))
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::AssetUrlHelper', 'EasyPatch::AssetUrlHelperPatch'
