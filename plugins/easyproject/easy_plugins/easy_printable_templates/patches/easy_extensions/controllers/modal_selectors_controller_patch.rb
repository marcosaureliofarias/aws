module EasyPrintableTemplates
  module ModalSelectorsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_printable_template_to_documents
          retrieve_query(EasyDocumentQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.document.default') : l("easy_query.easy_lookup.name.document.#{params[:query_name]}"))

          set_query(@query)
          sort_init(@query.sort_criteria_init)
          sort_update(@query.sortable_columns)

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count, show_ending_buttons: true)
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ModalSelectorsController', 'EasyPrintableTemplates::ModalSelectorsControllerPatch'
