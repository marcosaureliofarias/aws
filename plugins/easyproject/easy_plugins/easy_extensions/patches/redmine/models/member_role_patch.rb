module EasyPatch
  module MemberRolePatch
    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        validates_presence_of :member
        alias_method_chain :remove_member_if_empty, :easy_extensions
      end
    end

    module InstanceMethods
      def remove_member_if_empty_with_easy_extensions
        remove_member_if_empty_without_easy_extensions if member
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'MemberRole', 'EasyPatch::MemberRolePatch'
