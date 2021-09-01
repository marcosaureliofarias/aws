module EasyButtons
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        def get_epm_easy_buttons_toggling_container_options(page_module, options={})
          heading = l('easy_pages.modules.easy_buttons')

          entity_type_name = page_module.settings['button_type'].try(:underscore)
          if entity_type_name
            heading << " (#{l("label_#{entity_type_name}")})"
          end

          {
            heading: heading
          }
        end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyButtons::ApplicationHelperPatch'
