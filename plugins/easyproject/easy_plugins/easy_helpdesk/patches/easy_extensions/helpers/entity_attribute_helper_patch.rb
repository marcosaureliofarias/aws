module EasyHelpdesk
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_issue_attribute, :easy_helpdesk
        alias_method_chain :format_issue_attribute, :easy_helpdesk
        alias_method_chain :format_html_project_attribute, :easy_helpdesk
        alias_method_chain :format_project_attribute, :easy_helpdesk

        def format_html_easy_helpdesk_project_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :project
            link_to_project(value, {}, :title => l(:title_project_show, :projectname => value.name)) if value
          when :monthly_hours, :spent_time_last_month, :spent_time_current_month, :aggregated_hours_remaining,
              :aggregated_from_last_period, :remaining_hours
            unformatted_value ? easy_format_hours(unformatted_value, options) : ''
          else
            h(value)
          end
        end

        def format_easy_helpdesk_project_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_default_entity_attribute(attribute, unformatted_value, options)

          value = case attribute.name
          when :matching_emails
            if options[:entity]
              options[:entity].easy_helpdesk_project_matching.collect{|m| m.domain_name_with_email_field}.join(', ')
            end
          when :default_for_mailbox
            value.username_caption.to_s.strip if value
          when :watchers_ids
            if value && value.is_a?(Array)
              value.select{|uid| !uid.blank?}.collect{|uid| u = User.where(:id => uid).select([:firstname, :lastname]).first; u.name}.join(', ')
            end
          when :monthly_hours, :spent_time_last_month, :spent_time_current_month, :aggregated_hours_remaining,
              :aggregated_from_last_period, :remaining_hours
            unformatted_value ? (options[:no_html] ? format_locale_number(unformatted_value, options) : easy_format_hours(unformatted_value, options.reverse_merge(no_html: true))) : ''
          else
            value
          end

          value
        end

        def format_html_easy_sla_event_attribute(entity_class, attribute, unformatted_value, options={})
          easy_sla_event = options[:entity]
          value = format_default_entity_attribute(attribute, unformatted_value, options)

          case attribute.name
          when :issue, :project, :user
            if unformatted_value && !options[:no_link]
              link_to_entity(unformatted_value)
            else
              value
            end
          when :sla_resolve_fulfilment
            value = format_hours(unformatted_value)
            if unformatted_value && unformatted_value > 0.0
              content_tag(:span, value, class: 'color-positive')
            else
              value
            end
          when :first_response, :sla_response_fulfilment
            if !unformatted_value.nil?
              value = format_hours(unformatted_value)
              if easy_sla_event && !easy_sla_event.sla_response_fulfilment.nil? && easy_sla_event.sla_response_fulfilment > 0.0
                content_tag(:span, value, class: 'color-positive')
              else
                value
              end
            else
              '--:--'
            end
          else
            value
          end
        end
      end
    end

    module InstanceMethods
      def format_html_issue_attribute_with_easy_helpdesk(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :easy_due_date_time_remaining
          if options[:entity] && unformatted_value&.zero?
            return easy_format_hours(unformatted_value)
          end
          if options[:entity] && unformatted_value
            time_value = options[:entity].easy_due_date_time
            time = format_time(time_value)
            if Time.now < time_value
              title = l(:text_issue_easy_helpdesk_projects_sla_hours_to_solve_before_time, :time => time)
            else
              title = l(:text_issue_easy_helpdesk_projects_sla_hours_to_solve_after_time, :time => time)
            end
            if options[:entity].easy_time_to_solve_paused?
              title << ' - '
              title << l(:title_sla_waiting_for_client)
              content_tag(:span, l(:title_sla_waiting_for_client), :title => title)
            else
              easy_format_hours(unformatted_value, options.reverse_merge(title: title))
            end
          else
            ''
          end
        when :easy_response_date_time_remaining
          return easy_format_hours(unformatted_value) if options[:entity] && unformatted_value.zero?
          if options[:entity] && unformatted_value
            time_value = options[:entity].easy_response_date_time
            time = format_time(time_value)
            if Time.now < time_value
              title = l(:text_issue_easy_helpdesk_projects_sla_hours_to_response_before_time, :time => time)
            else
              title = l(:text_issue_easy_helpdesk_projects_sla_hours_to_response_after_time, :time => time)
            end
            if options[:entity].easy_time_to_solve_paused?
              title << ' - '
              title << l(:title_sla_waiting_for_client)
              content_tag(:span, l(:title_sla_waiting_for_client), :title => title)
            else
              easy_format_hours(unformatted_value, options.reverse_merge(title: title))
            end
          else
            ''
          end
        when :easy_helpdesk_project_monthly_hours
          easy_format_hours(unformatted_value || 0, options)
        when :easy_helpdesk_need_reaction
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)
          entity_multieditable_tag(entity_class, 'easy_helpdesk_need_reaction', h(value), options, {:value => unformatted_value, :type => 'select', :source => boolean_source})
        when :easy_helpdesk_ticket_owner
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)
          link = render_user_attribute(unformatted_value, value, options)
          if options[:entity] && options[:entity].maintained_by_easy_helpdesk? && options[:entity].disabled_core_fields.exclude?('easy_helpdesk_ticket_owner_id')
            entity_multieditable_tag(entity_class, 'easy_helpdesk_ticket_owner_id', link, options,
              {value: options[:entity].easy_helpdesk_ticket_owner_id, type: 'select',
                autocomplete_source: ['assignable_users', {issue_id: options[:entity].id}]})
          else
            link
          end
        else
          format_html_issue_attribute_without_easy_helpdesk(entity_class, attribute, unformatted_value, options)
        end
      end

      def format_issue_attribute_with_easy_helpdesk(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :easy_response_date_time_remaining
          if options[:entity] && (hours = unformatted_value)
            options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
          else
            ''
          end
        when :easy_due_date_time_remaining
          if options[:entity] && (hours = unformatted_value)
            options[:no_html] ? format_locale_number(hours) : easy_format_hours(hours, options.reverse_merge(no_html: true))
          else
            ''
          end
        when :easy_response_date_time
          format_time(unformatted_value) if unformatted_value
        when :easy_helpdesk_project_monthly_hours
          options[:no_html] ? format_locale_number(unformatted_value || 0) : easy_format_hours(unformatted_value || 0, options.reverse_merge(no_html: true))
        else
          format_issue_attribute_without_easy_helpdesk(entity_class, attribute, unformatted_value, options)
        end
      end

      def format_html_project_attribute_with_easy_helpdesk(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :'easy_helpdesk_project.spent_time_last_month',
            :'easy_helpdesk_project.spent_time_current_month', :'easy_helpdesk_project.aggregated_hours_remaining',
            :'easy_helpdesk_project.aggregated_from_last_period', :'easy_helpdesk_project.remaining_hours'
          unformatted_value ? easy_format_hours(unformatted_value, options) : ''
        when :'easy_helpdesk_project.monthly_hours'
          easy_format_hours(unformatted_value || 0, options) if options[:entity] && options[:entity].easy_helpdesk_project
        else
          format_html_project_attribute_without_easy_helpdesk(entity_class, attribute, unformatted_value, options)
        end
      end

      def format_project_attribute_with_easy_helpdesk(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :'easy_helpdesk_project.spent_time_last_month',
            :'easy_helpdesk_project.spent_time_current_month', :'easy_helpdesk_project.aggregated_hours_remaining',
            :'easy_helpdesk_project.aggregated_from_last_period', :'easy_helpdesk_project.remaining_hours', :'easy_helpdesk_project.easy_helpdesk_total_spent_time'
          unformatted_value ? (options[:no_html] ? format_locale_number(unformatted_value) : easy_format_hours(unformatted_value, options.reverse_merge(no_html: true))) : ''
        when :'easy_helpdesk_project.monthly_hours'
          if options[:entity] && options[:entity].easy_helpdesk_project
            options[:no_html] ? format_locale_number(unformatted_value || 0) : easy_format_hours(unformatted_value || 0, options.reverse_merge(no_html: true))
          end
        else
          format_project_attribute_without_easy_helpdesk(entity_class, attribute, unformatted_value, options)
        end
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyHelpdesk::EntityAttributeHelperPatch'
