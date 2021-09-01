module EasyMoney
  module ModalSelectorsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_money_expected_expense
          render_modal_selector_easy_money_entities_list(EasyMoneyExpectedExpenseQuery)
        end

        def easy_money_expected_revenue
          render_modal_selector_easy_money_entities_list(EasyMoneyExpectedRevenueQuery)
        end

        def easy_money_other_expense
          render_modal_selector_easy_money_entities_list(EasyMoneyOtherExpenseQuery)
        end

        def easy_money_other_revenue
          render_modal_selector_easy_money_entities_list(EasyMoneyOtherRevenueQuery)
        end

        def easy_money_travel_expense
          render_modal_selector_easy_money_entities_list(EasyMoneyTravelExpenseQuery)
        end

        def render_modal_selector_easy_money_entities_list(query_class)
          retrieve_query(query_class)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.group.default') : l("easy_query.easy_lookup.name.group.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria_init)
          sort_update(@query.sortable_columns)

          yield(@query) if block_given?

          prepare_easy_query_render

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {selected_values: prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ModalSelectorsController', 'EasyMoney::ModalSelectorsControllerPatch'
