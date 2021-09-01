module EasyCrm
  module IssuesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_crm_cases_relations_field_tag(field_name, field_id, values = [], options = {})
          selected_values = EasyExtensions::FieldFormats::EasyLookup.entity_ids_to_lookup_values('EasyCrmCase', values, :display_name => :name)
          easy_modal_selector_field_tag('EasyCrmCase', 'link_with_name', field_name, field_id, selected_values, options)
        end

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyCrm::IssuesHelperPatch'
