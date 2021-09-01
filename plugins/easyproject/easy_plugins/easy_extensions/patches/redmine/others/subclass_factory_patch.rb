module EasyPatch
  module SubclassFactoryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :get_subclass, :easy_extensions

        class << self


        end
      end
    end

    module ClassMethods


    end

    module InstanceMethods

      def get_subclass_with_easy_extensions(class_name)
        klass = nil
        begin
          klass = class_name.to_s.classify.constantize
        rescue
          # invalid class name
        end
        unless descendants.include? klass
          klass = nil
        end
        klass
      end

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::SubclassFactory::ClassMethods', 'EasyPatch::SubclassFactoryPatch'
