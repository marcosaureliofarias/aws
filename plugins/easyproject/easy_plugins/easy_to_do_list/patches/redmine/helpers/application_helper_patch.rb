module EasyToDoListModule
  module ApplicationHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # def easy_to_do_list_source_handle_tag(entity)
        #   link_to('',{}, :class => 'icon icon-fullscreen xl-icon easy-to-do-list-source-handle', :title => l(:title_drag_entity_into_to_do_list),
        #   :'data-new-easy-to-do-list-item-attributes' => "{\"easy_to_do_list_item\": {\"name\": \"#{j entity.to_s}\", \"entity_type\": \"#{entity.class.name}\", \"entity_id\": \"#{entity.id}\"}}") unless is_mobile_device?
        # end

      end
    end

    module InstanceMethods

    end

  end

end
# EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyToDoListModule::ApplicationHelperPatch'
