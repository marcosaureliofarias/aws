module EasyCrm
  module ModalSelectorsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

      end
    end

    module InstanceMethods

      def easy_crm_case
        retrieve_query(EasyCrmCaseQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_crm_case.default') : l("easy_query.easy_lookup.name.easy_crm_case.#{params[:query_name]}"))

        set_query(@query)

        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        prepare_easy_query_render

        if request.xhr? && !@entities
          render_404
          return false
        end

        # entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)
        # options = {:button_close_label => l('modal_labels.cancel'), :button_close_title => l('modal_titles.cancel')}

        if loading_group?
          render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
        else
          render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
        end
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch('ModalSelectorsController', 'EasyCrm::ModalSelectorsControllerPatch')
