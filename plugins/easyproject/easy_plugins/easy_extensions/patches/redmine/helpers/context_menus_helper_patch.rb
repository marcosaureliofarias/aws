module EasyPatch
  module ContextMenusHelperPatch

    def self.included(base)
      base.class_eval do
        # @param [String] name - form name, for params
        # @param [String] update_path - route name for bulk update
        # @param [Array<Integer>] ids - entities IDs for update
        # @param [CustomField] field
        # @param [Object] value of field of the object that we want to update or nil (if more objects)
        def custom_field_context_menu_link(name, update_path, ids, field, text, value, entity_value_for_field = nil)
          id_or_ids = ids.is_a?(Array) ? :ids : :id
          context_menu_link(text,
                            send(update_path, id_or_ids => ids, name => {'custom_field_values' => {field.id => value}}, :back_url => back_url),
                            :method => :put,
                            :selected => value == entity_value_for_field)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ContextMenusHelper', 'EasyPatch::ContextMenusHelperPatch'
