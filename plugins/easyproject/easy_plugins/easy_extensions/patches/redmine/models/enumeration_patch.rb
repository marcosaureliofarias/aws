module EasyPatch
  module EnumerationPatch

    def self.included(base)
      base.extend ClassMethods
      base.include(InstanceMethods)
      base.class_eval do
        validates_length_of :description, maximum: 255

        after_save :invalidate_cache
        after_destroy :invalidate_cache

        class << self
          alias_method_chain :default, :easy_extensions
          alias_method_chain :get_subclasses, :easy_extensions
        end

        def invalidate_cache
          RequestStore.store["default_enum_#{self.class.name}".to_sym] = nil
        end

        def self.disabled_sti_class
          EasyDisabledEnumeration
        end

        def form_partial
          'enumerations/form'
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def get_subclasses_with_easy_extensions
        get_subclasses_without_easy_extensions.reject { |s| s == EasyDisabledEnumeration }
      end

      # adds a cache on this method.
      def default_with_easy_extensions
        RequestStore.store["default_enum_#{self.name}".to_sym] ||= default_without_easy_extensions
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Enumeration', 'EasyPatch::EnumerationPatch'
