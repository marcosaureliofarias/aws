module EasyPatch
  module MenuManagerMenuNodePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        attr_accessor :project, :menu_name

      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def remove_children
        @children         = []
        @last_items_count = 0
      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager::MenuNode', 'EasyPatch::MenuManagerMenuNodePatch'
