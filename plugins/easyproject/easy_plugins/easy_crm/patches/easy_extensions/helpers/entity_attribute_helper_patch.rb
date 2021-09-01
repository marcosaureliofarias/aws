module EasyCrm
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_issue_attribute, :easy_crm

        def format_html_easy_crm_case_attribute(entity_class, attribute, unformatted_value, options={})
          options[:inline_editable] = true
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :name
            if options[:entity] && !options[:no_link]
              drag_html_attributes = options[:entity] && !options[:modal] ? {
                'data-entity-id'   => options[:entity].id,
                'data-entity-type' => entity_class.name,
                'data-handler'     => 'true'
              } : {}
              entity_multieditable_tag(entity_class, 'name', link_to(value, easy_crm_case_path(options[:entity]), drag_html_attributes), options, {:value => value || '-'})
            else
              value
            end
          when :price
            currency = nil
            if attribute.is_a?(EasyQueryCurrencyColumn) && attribute.query && attribute.query.easy_currency_code
              currency = attribute.query.easy_currency_code
            elsif options[:entity]
              currency_option = options[:entity].currency_options.detect{|x| x[:price_method] == attribute.name}
              currency = options[:entity].send(currency_option[:currency_method]) if currency_option
            else
              currency = ''
            end
            entity_multieditable_tag(entity_class, 'price', format_price(unformatted_value, currency, options), options, {:value => value})
          when :assigned_to, :external_assigned_to_id, :author
            entity_multieditable_tag(entity_class, attribute.name.to_s + '_id', render_user_attribute(unformatted_value, value, options), options,
            {
              :autocomplete_source => ['assignable_users', {:entity_type => 'EasyCrmCase', :entity_id => options[:entity].try(:id)}],
              :type => 'select'
            })
          when :easy_crm_case_status
            entity_multieditable_tag(entity_class, 'easy_crm_case_status_id', value && value.name, options,
            {
              :autocomplete_source => 'easy_crm_case_statuses',
              :type => 'select',
              :value => options[:entity].try(:easy_crm_case_status_id)
            })
          when :email
            entity_multieditable_tag(entity_class, 'email', mail_to(value), options, {:value => value})
          when :telephone
            entity_multieditable_tag(entity_class, 'telephone', value, options, {:value => value || '-'})
          when :contract_date
            entity_multieditable_tag(entity_class, 'contract_date', h(value), options, {:value => unformatted_value.to_s, :type => 'dateui'})
          when :next_action
            entity_multieditable_tag(entity_class, 'next_action', h(value), options, {:value => unformatted_value.to_s, :type => 'dateui'})
          when :need_reaction
            entity_multieditable_tag(entity_class, 'need_reaction', h(value), options, {:value => unformatted_value, :type => 'select', :source => boolean_source})
          when :description
            textilizable(value)
          when :name_and_cf
            name_link = link_to(options[:entity].name, easy_crm_case_path(options[:entity]))
            "#{name_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
          when /easy_contact_type_/
            if value
              Array(value).map{|x| link_to_easy_contact(x)}.join(', ').html_safe
            end
          when :easy_entity_activities
            if unformatted_value.present?
              unformatted_value.sorted.collect {|easy_entity_activity| "#{easy_entity_activity.category} (#{format_date(easy_entity_activity.start_time)})"}.join(', ').html_safe
            end
          else
            h(value)
          end
        end

        def format_html_easy_user_target_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
            when :target
              if attribute.is_a?(EasyQueryCurrencyColumn) && attribute.query && attribute.query.easy_currency_code
                currency = attribute.query.easy_currency_code
              elsif options[:entity]
                currency_option = options[:entity].currency_options.detect{|option| option[:price_method] == attribute.name}
                currency = options[:entity].send(currency_option[:currency_method]) if currency_option
              else
                currency = ''
              end
              content_tag :span, format_price(unformatted_value, currency, options)
            else
              h(value)
          end
        end
      end
    end

    module InstanceMethods

      def format_html_issue_attribute_with_easy_crm(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :easy_crm_cases
          if unformatted_value.any? && options[:entity]
            l(:label_relates_to).concat(unformatted_value.collect {|related_crm_case| " #{link_to_easy_crm_case(related_crm_case)}"}.join(', ').html_safe)
          end
        else
          format_html_issue_attribute_without_easy_crm(entity_class, attribute, unformatted_value, options)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyCrm::EntityAttributeHelperPatch'
