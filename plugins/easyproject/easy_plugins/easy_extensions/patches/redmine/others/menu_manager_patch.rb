module EasyPatch
  module MenuManagerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        def self.allowed_items(menu_name, user, project)
          items(menu_name).root.children.select { |item| item.allowed?(user, project) }
        end

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager', 'EasyPatch::MenuManagerPatch'
