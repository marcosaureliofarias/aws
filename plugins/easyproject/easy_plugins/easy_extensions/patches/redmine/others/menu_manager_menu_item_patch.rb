module EasyPatch
  module MenuManagerMenuItemPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :allowed?, :easy_extensions

        def url_params
          {}
        end

      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def allowed_with_easy_extensions?(user, entity)
        project = entity.try(:project)
        if url.blank?
          # this is a virtual node that is only there for its children to be displayed in the menu
          # it is considered an allowed node if at least one of the children is allowed
          all_children = children
          all_children += child_menus.call(entity) if child_menus
          return false unless all_children.detect { |child| child.allowed?(user, entity) }
        elsif user && project
          if permission
            unless user.allowed_to?(permission, project)
              return false
            end
          elsif permission.nil? && url.is_a?(Hash)
            unless user.allowed_to?(url, project)
              return false
            end
          end
        end
        if condition && !condition.call(entity)
          # Condition that doesn't pass
          return false
        end
        true
      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager::MenuItem', 'EasyPatch::MenuManagerMenuItemPatch'
