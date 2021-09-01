module EasyPatch
  module AccessControlMapperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :permission, :easy_extensions

        def easy_category(name, options = {})
          @easy_category = name
          yield self
          @easy_category = nil
        end

      end
    end

    module InstanceMethods

      def permission_with_easy_extensions(name, hash, options = {})
        @permissions             ||= []
        options[:easy_category]  = @easy_category
        options[:project_module] = @project_module
        @permissions << Redmine::AccessControl::Permission.new(name, hash, options)
      end

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl::Mapper', 'EasyPatch::AccessControlMapperPatch'
