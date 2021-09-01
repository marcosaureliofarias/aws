module EasyCrm
  module EasyEntityActionsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_crm_case_query_additional_beginning_buttons(entity, options = {})
          s = ''

          if options[:eea_beginning_buttons]
            s << link_to(l(:button_execute), execute_easy_entity_action_path(@easy_entity_action, :entity_type => entity.class.name, :entity_id => entity.id), :class => 'button-positive', :title => l(:button_execute))
          end

          s.html_safe
        end

      end
    end

    module InstanceMethods

    end
  end

end
EasyExtensions::PatchManager.register_helper_patch 'EasyEntityActionsHelper', 'EasyCrm::EasyEntityActionsHelperPatch'
