# encoding: utf-8

module EasyMoney
  module ApplicationHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def link_to_easy_money(entity, options={})
          case entity.class
          when EasyMoneyTravelExpense
            link_to_easy_money_travel_expense(entity, options)
          when EasyMoneyTravelCost
            link_to_easy_money_travel_cost(entity, options)
          when EasyMoneyExpectedExpense
            link_to_easy_money_expected_expense(entity, options)
          when EasyMoneyOtherExpense
            link_to_easy_money_other_expense(entity, options)
          when EasyMoneyExpectedRevenue
            link_to_easy_money_expected_revenue(entity, options)
          when EasyMoneyOtherRevenue
            link_to_easy_money_other_revenue(entity, options)
          end
        end

        def link_to_easy_money_travel_expense(entity, options={})
          link_to(entity.name, edit_easy_money_travel_expense_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_travel_cost(entity, options={})
          link_to(entity.name, edit_easy_money_travel_cost_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_expected_expense(entity, options={})
          link_to(entity.name, edit_easy_money_expected_expense_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_other_expense(entity, options={})
          link_to(entity.name, edit_easy_money_other_expense_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_expected_revenue(entity, options={})
          link_to(entity.name, edit_easy_money_expected_revenue_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_other_revenue(entity, options={})
          link_to(entity.name, edit_easy_money_other_revenue_path(entity), options.merge(url_standard_options(options)))
        end

        def link_to_easy_money_project_cache(entity, options={})
          link_to(entity.project.name, project_easy_money_path(entity.project), options.merge(url_standard_options(options)))
        end

        def render_easy_entity_card_easy_money(easy_money, source_entity, options = {})
          easy_entity_card(easy_money, source_entity, options) do |eec|
            eec.link_to_entity link_to_easy_money(easy_money)
            eec.detail(controller.render_to_string :partial => 'easy_entity_cards/easy_entity_card_easy_money_detail', :layout => false, :formats => [:html], :locals => {:easy_money => easy_money, :options => options})
            eec.footer_left content_tag(:span, easy_money.tag_list.map{|t| link_to(t, easy_tag_path(t))} .join(', ').html_safe, :class => 'entity-array') if !easy_money.tag_list.blank?
          end
        end

        def render_easy_entity_card_easy_money_travel_expense(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

        def render_easy_entity_card_easy_money_travel_cost(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

        def render_easy_entity_card_easy_money_expected_expense(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

        def render_easy_entity_card_easy_money_other_expense(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

        def render_easy_entity_card_easy_money_expected_revenue(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

        def render_easy_entity_card_easy_money_other_revenue(easy_money, source_entity, options = {})
          render_easy_entity_card_easy_money(easy_money, source_entity, options)
        end

      end
    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyMoney::ApplicationHelperPatch'
