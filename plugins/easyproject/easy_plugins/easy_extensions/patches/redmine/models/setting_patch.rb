module EasyPatch
  module SettingPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :value, :easy_extensions

      end
    end

    module InstanceMethods
      def value_with_easy_extensions
        v = value_without_easy_extensions
        if v.is_a?(Hash) && !v.is_a?(::ActiveSupport::HashWithIndifferentAccess)
          ::ActiveSupport::HashWithIndifferentAccess.new(v)
        else
          v
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Setting', 'EasyPatch::SettingPatch'
