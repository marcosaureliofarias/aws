module EasyMoney
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_money_query_additional_ending_buttons(entity, options = {})
          klass = entity.class.name.underscore
          controller = klass.pluralize
          permission = klass.sub('easy_money_', 'easy_money_manage_').to_sym
          s = ''
          if User.current.allowed_to?(permission, entity.project)
            s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), {:controller => controller, :action => 'edit', :id => entity, :back_url => original_url}, :class => 'icon icon-edit')
            s << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), {:controller => controller, :action => 'destroy', :id => entity, :back_url => original_url}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
          end
          s.html_safe
        end
        alias_method :easy_money_expected_expense_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons
        alias_method :easy_money_expected_revenue_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons
        alias_method :easy_money_other_expense_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons
        alias_method :easy_money_other_revenue_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons
        alias_method :easy_money_travel_cost_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons
        alias_method :easy_money_travel_expense_query_additional_ending_buttons, :easy_money_query_additional_ending_buttons

        def easy_money_query_additional_beginning_buttons(entity, options = {})
          s = ''
          if entity.easy_external_id
            s << content_tag(:span, '', :title => l(:title_model_has_easy_external_id), :class => 'icon icon-relation')
          end
          s.html_safe
        end
        alias_method :easy_money_expected_expense_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
        alias_method :easy_money_expected_revenue_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
        alias_method :easy_money_other_expense_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
        alias_method :easy_money_other_revenue_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
        alias_method :easy_money_travel_cost_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
        alias_method :easy_money_travel_expense_query_additional_beginning_buttons, :easy_money_query_additional_beginning_buttons
      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyMoney::EasyQueryButtonsHelperPatch'
