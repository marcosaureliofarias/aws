module EasyPatch
  module InheritancePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :find_sti_class, :easy_extensions
      end
    end

    module InstanceMethods
      def find_sti_class_with_easy_extensions(type_name)
        find_sti_class_without_easy_extensions(type_name)
      rescue ActiveRecord::SubclassNotFound
        if self.respond_to?(:disabled_sti_class)
          self.disabled_sti_class
        else
          raise
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Inheritance::ClassMethods', 'EasyPatch::InheritancePatch'
