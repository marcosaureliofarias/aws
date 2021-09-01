module EasyMoney
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_project_attribute, :easy_money
        alias_method_chain :format_html_time_entry_attribute, :easy_money
        alias_method_chain :format_html_user_attribute, :easy_money
        alias_method :format_price_helper, :format_easy_money_price

        def format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :price1, :price2
            project = options[:entity] ? options[:entity].project : options[:project]
            easy_currency_code = attribute.query.try(:easy_currency_code)
            format_easy_money_price(unformatted_value, project, easy_currency_code, options.merge(round: true))
          when :vat
            if options[:entity] && options[:entity].price1 > 0.0 && options[:entity].price2 > 0.0
              price = options[:entity].price1 - options[:entity].price2
              easy_currency_code = attribute.query.try(:easy_currency_code)
              format_easy_money_price(price, options[:entity].project, easy_currency_code, options.merge(round: true))
            else
              format_price(0.0)
            end
          when :project
            link_to_project(value) if value
          when :issue
            link_to_issue(value) if value
          when :version
            link_to_version(value) if value
          when :description
            textilizable(value.to_s.html_safe)
          when :easy_invoice
            link_to_easy_invoice(unformatted_value) if unformatted_value && User.current.allowed_to?(:easy_invoicing_show_easy_invoice, options[:entity].try(:project))
          when :attachments
            truncate_objects(value){ |attach| attach.map!{|a| link_to_attachment(a, download: true, class: 'attachment')}}.html_safe if value
          when :name, :name_and_cf
            if options[:entity] && !options[:no_link]
              link_to(value, options[:easy_money_entity_path])
            else
              h(value)
            end
          when :entity_title
            if options[:entity] && !options[:no_link]
              link_to_entity(options[:entity].entity)
            else
              h(value)
            end
          else
            h(value)
          end
        end

        def format_html_easy_money_expected_expense_attribute(entity_class, attribute, unformatted_value, options={})
          if [:name, :name_and_cf].include?(attribute.name)
            options[:easy_money_entity_path] = edit_easy_money_expected_expense_path(options[:entity]) if options[:entity] && !options[:no_link]
          end
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_expected_revenue_attribute(entity_class, attribute, unformatted_value, options={})
          if [:name, :name_and_cf].include?(attribute.name)
            options[:easy_money_entity_path] = edit_easy_money_expected_revenue_path(options[:entity]) if options[:entity] && !options[:no_link]
          end
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_other_expense_attribute(entity_class, attribute, unformatted_value, options={})
          if [:name, :name_and_cf].include?(attribute.name)
            options[:easy_money_entity_path] = edit_easy_money_other_expense_path(options[:entity]) if options[:entity] && !options[:no_link]
          end
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_other_revenue_attribute(entity_class, attribute, unformatted_value, options={})
          if [:name, :name_and_cf].include?(attribute.name)
            options[:easy_money_entity_path] = edit_easy_money_other_revenue_path(options[:entity]) if options[:entity] && !options[:no_link]
          end
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_travel_cost_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.name == :price_per_unit
            price = 0.0
            easy_currency_code = attribute.query.try(:easy_currency_code) || options[:project].try(:easy_currency_code)
            entity = options[:entity]

            if entity && entity.metric_units > 0
              price = entity.price1(easy_currency_code) / entity.metric_units
            end

            format_easy_money_price(price, options[:project], easy_currency_code)
          else
            format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
          end
        end

        def format_html_easy_money_travel_expense_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.name == :name
            options[:easy_money_entity_path] = edit_easy_money_travel_expense_path(options[:entity]) if options[:entity] && !options[:no_link]
          end
          if attribute.name == :price_per_day
            price = 0.0
            easy_currency_code = attribute.query.try(:easy_currency_code) || options[:project].try(:easy_currency_code)
            entity = options[:entity]

            if entity && entity.days_count > 0
              price = entity.price1(easy_currency_code) / entity.days_count
            end

            format_easy_money_price(price, options[:project], easy_currency_code)
          else
            format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
          end
        end

        def format_html_easy_money_project_cache_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :sum_of_expected_hours, :sum_of_estimated_hours, :sum_of_timeentries
            easy_format_hours(unformatted_value, options)
          when :project, :parent_project, :main_project
            link_to_project(value, jump: 'easy_money') if value
          when :profit_margin
            format_number( "%.2f %%" % unformatted_value)
          when :cost_ratio
            format_number(unformatted_value, nil, percentage: true)
          else
            if [:integer, :decimal, :float].include?(EasyMoneyProjectCache.type_for_attribute(attribute.name.to_s).try(:type))
              easy_currency_code = attribute.query.try(:easy_currency_code)
              project = options[:entity].try(:project)
              format_easy_money_price(unformatted_value, project, easy_currency_code, options.merge(round: true))
            else
              h(value)
            end
          end
        end

        def format_html_easy_money_issue_budget_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.name.in? EasyMoneyIssuesBudgetQuery.easy_money_columns
            entity = options[:entity]
            project = entity.project

            format_easy_money_price unformatted_value, project, entity.easy_currency_code
          elsif attribute.name.in? EasyMoneyIssuesBudgetQuery.easy_money_margin_columns
            number_to_percentage unformatted_value, precision: 2
          else
            format_html_issue_attribute(Issue, attribute, unformatted_value, options)
          end
        end

        def format_html_easy_money_crm_case_budget_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.name.in? EasyMoneyCrmCasesBudgetQuery.easy_money_columns
            entity = options[:entity]
            project = entity.project

            format_easy_money_price unformatted_value, project, entity.easy_currency_code
          elsif attribute.name.in? EasyMoneyCrmCasesBudgetQuery.easy_money_margin_columns
            number_to_percentage unformatted_value, precision: 2
          else
            format_html_easy_crm_case_attribute(EasyCrmCase, attribute, unformatted_value, options)
          end
        end

      end

    end

    module InstanceMethods
      def format_html_project_attribute_with_easy_money(entity_class, attribute, unformatted_value, options={})
        if /^empe_cashflow_/.match?(attribute.name)
          project = options[:entity] ? options[:entity].project : options[:project]
          easy_currency_code = attribute.query.try(:easy_currency_code)

          format_easy_money_price(unformatted_value, project, easy_currency_code, round: true)
        elsif attribute.name == :"easy_money.cost_ratio"
          format_number(unformatted_value, nil, percentage: true)
        else
          format_html_project_attribute_without_easy_money(entity_class, attribute, unformatted_value, options)
        end
      end

      def format_html_time_entry_attribute_with_easy_money(entity_class, attribute, unformatted_value, options = {})
        case attribute.name
          when *EasyMoneyRateType.rate_type_cache.map { |r| (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + r.name).to_sym }
            currency = nil
            if attribute.is_a?(EasyQueryCurrencyColumn) && attribute.query && attribute.query.easy_currency_code
              currency = attribute.query.easy_currency_code
            elsif options[:entity] && options[:entity].respond_to?(:currency_options)
              currency_option = options[:entity].currency_options.detect { |x| x[:price_method] == attribute.name }
              currency = options[:entity].send(currency_option[:currency_method]) if currency_option
              currency ||= options[:entity].default_currency
            else
              currency = ''
            end
            currency = EasyCurrency.get_symbol(currency)
            content_tag :span, format_price(unformatted_value, currency, options)
          else
            format_html_time_entry_attribute_without_easy_money(entity_class, attribute, unformatted_value, options)
        end

      end

      def format_html_user_attribute_with_easy_money(entity_class, attribute, unformatted_value, options = {})
        if /^rate_type_\d+_unit_rate$/.match?(attribute.name)
          entity = options[:entity]
          project = attribute.project

          price = unformatted_value.presence || 0
          easy_currency_code = entity.attributes[attribute.unit_rate_currency_column] || project.try(:easy_currency_code) || EasyCurrency.default_code

          editable_options = {
              value: {
                  unit_rate: price,
                  easy_currency_code: easy_currency_code
              },
              name: 'easy_money_rate',
              type: 'price',
              url: url_for(controller: 'easy_money_rates', action: 'inline_update', format: :json, rate_type_id: attribute.rate_type.id, entity_type: 'Principal', entity_id: entity.id)
          }

          content_tag(:span, class: 'multieditable', data: editable_options) do
            concat format_easy_money_price price, options[:project], easy_currency_code, round: false, precision: 2

            if project && easy_currency_code && project.easy_currency_code != easy_currency_code && attribute.project_currency_unit_rate_column && entity.attributes[attribute.project_currency_unit_rate_column].present?
              unit_rate_in_project_currency = format_easy_money_price(entity.attributes[attribute.project_currency_unit_rate_column], project, round: false, precision: 2)

              concat " (#{unit_rate_in_project_currency})".html_safe
            end
          end
        else
          format_html_user_attribute_without_easy_money(entity_class, attribute, unformatted_value, options)
        end
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyMoney::EntityAttributeHelperPatch'
