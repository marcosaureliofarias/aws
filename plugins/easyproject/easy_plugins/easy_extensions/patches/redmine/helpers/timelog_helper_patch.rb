module EasyPatch
  module TimelogHelperPatch
    include Redmine::Export::PDF

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_criteria_value, :easy_extensions

        def self.activity_collection(user = nil, role_id = nil, project = nil)
          user ||= User.current
          if project.nil?
            activities = TimeEntryActivity.shared.sorted
          else
            activities = project.activities_per_role(user, role_id)
          end

          return activities
        end

        def activity_collection(user = nil, role_id = nil, project = nil)
          project ||= (@new_project || @project)
          TimelogHelper.activity_collection(user, role_id, project)
        end

        def easy_range_to_string(value)
          time = case value
                 when String
                   begin
                     value.to_time
                   rescue ArgumentError
                   end
                 when Time, DateTime
                   value
                 end
          (hour_to_string(time.hour) + ':' + min_to_string(time.min)).html_safe if time
        end

        def period_label(period)
          case period
          when 'all'
            l(:label_all_time)
          when 'today'
            l(:label_today)
          when 'yesterday'
            l(:label_yesterday)
          when 'current_week'
            l(:label_this_week)
          when 'last_week'
            l(:label_last_week)
          when 'last_2_weeks'
            l(:label_last_n_weeks, 2)
          when '7_days'
            l(:label_last_n_days, 7)
          when 'current_month'
            l(:label_this_month)
          when 'last_month'
            l(:label_last_month)
          when '30_days'
            l(:label_last_n_days, 30)
          when '90_days'
            l(:label_last_n_days, 90)
          when 'current_year'
            l(:label_this_year)
          when 'last_year'
            l(:label_last_year)
          else
            ''
          end
        end

        def render_api_time_entry(api, time_entry)
          api.time_entry do
            api.id(time_entry.id)
            api.project(:id => time_entry.project_id, :name => time_entry.project.name) unless time_entry.project.nil?
            api.issue(:id => time_entry.issue_id) unless time_entry.issue.nil?
            api.user(:id => time_entry.user_id, :name => time_entry.user.name) unless time_entry.user.nil?
            api.activity(:id => time_entry.activity_id, :name => time_entry.activity.name) unless time_entry.activity.nil?
            api.hours(time_entry.hours)
            api.comments(time_entry.comments)
            api.spent_on(time_entry.spent_on)
            api.easy_range_from(time_entry.easy_range_from)
            api.easy_range_to(time_entry.easy_range_to)
            api.easy_external_id(time_entry.easy_external_id)
            api.entity_id(time_entry.entity_id)
            api.entity_type(time_entry.entity_type)
            api.created_on(time_entry.created_on)
            api.updated_on(time_entry.updated_on)

            call_hook(:helper_timelog_render_api_time_entry, { :api => api, :time_entry => time_entry })

            render_api_custom_values time_entry.visible_custom_field_values, api
          end
        end

        def hours_selector(time_entry, tag_name_prefix)
          if EasySetting.value('timeentry_hours_selector', time_entry.project) == 'select'
            hours_selector_with_select(time_entry, tag_name_prefix)
          else
            hours_selector_with_textbox(time_entry, tag_name_prefix)
          end
        end

        def hours_selector_with_textbox(time_entry, tag_name_prefix)
          s = ''
          s << label_for_field(:hours, { :required => true, :additional_for => tag_name_prefix })
          s << text_field_tag("#{tag_name_prefix}[hours]", time_entry && time_entry.hours, :size => 4, :placeholder => l(:field_hours))

          return s.html_safe
        end

        def hours_selector_with_select(time_entry, tag_name_prefix)
          selected_hours, selected_minutes = 0, 0

          if time_entry && time_entry.hours
            hours            = time_entry.hours.to_i
            selected_hours   = hours.to_s
            selected_minutes = ((time_entry.hours - hours) * 60).to_i.to_s
          end

          s = ''
          s << label_tag("#{tag_name_prefix}[hours]", l(:field_hours), :class => 'required')
          s << hidden_field_tag("#{tag_name_prefix}[hours]", time_entry && time_entry.hours)
          s << select_tag("#{tag_name_prefix}[hours_hour]", options_for_select(9.times.collect { |h| [h, h.to_s] }, :selected => selected_hours), :class => 'small-fixed-select',
                          :onchange                                                                                                                      => "$('##{convert_form_name_to_id(tag_name_prefix)}_hours').val(parseInt($(this).val()) + (parseInt($('##{convert_form_name_to_id(tag_name_prefix)}_hours_minute').val()) / 60.00))")
          s << '&nbsp;:&nbsp;'
          s << select_tag("#{tag_name_prefix}[hours_minute]", options_for_select([['00', '00'], ['15', '15'], ['30', '30'], ['45', '45']], :selected => selected_minutes), :class => 'small-fixed-select',
                          :onchange                                                                                                                                               => "var i =$('##{convert_form_name_to_id(tag_name_prefix)}_hours'); i.val((parseInt(i.val()) + parseFloat(parseInt($(this).val()) / 60.00)))")

          s.html_safe
        end

        def timelog_comment_tag(name, value = nil, options = {})
          tag      = ''
          field_id = "#{'modal_' if options[:modal]}time_entry_comment"
          if options.delete(:force_text_field) || !options[:editor_enabled]
            tag << text_field_tag(name, value, options)
          else
            tag << text_area_tag(name, value, options.merge(:class => 'wiki-edit', :size => '5x3', :id => field_id))

            tag << wikitoolbar_for(field_id, preview_text_path, { :custom => 'height: 100' }) unless in_mobile_view?
          end

          return tag.html_safe
        end

        def report_to_xlsx(report, query, options = {})
          EasyExtensions::Export::XlsxReport.new(report, query, options).output
        end

        def report_criteria_to_xlsx(entities, available_criteria, columns, criteria, periods, hours, level = 0)
          hours.collect { |h| h[criteria[level]].to_s }.uniq.each do |value|
            hours_for_value = select_hours(hours, criteria[level], value)
            next if hours_for_value.empty?
            row = [''] * level
            row << format_criteria_value(available_criteria[criteria[level]], value, false).to_s
            row   += [''] * (criteria.length - level - 1)
            total = 0
            periods.each do |period|
              sum   = sum_hours(select_hours(hours_for_value, columns, period.to_s))
              total += sum
              row << (sum > 0 ? format_locale_number(sum) : '')
            end
            row << format_locale_number(total)
            entities << row
            if criteria.length > level + 1
              report_criteria_to_xlsx(entities, available_criteria, columns, criteria, periods, hours_for_value, level + 1)
            end
          end
        end

        def render_timelog_breadcrumb
          return unless @project
          return if @only_me

          links = Array.new
          links << link_to(l(:label_project_all), { :project_id => nil, :issue_id => nil })
          @project.self_and_ancestors.collect do |p|
            links << ((User.current.allowed_to?(:view_time_entries, p, :global => true)) ? link_to(p.name, { :project_id => p, :issue_id => nil }) : content_tag(:span, p.name))
          end if @project
          links << link_to_issue(@issue) if @issue
          links << link_to_entity(@entity) if @entity

          breadcrumb links
        end

      end
    end

    module InstanceMethods
      def format_criteria_value_with_easy_extensions(criteria_options, value, html = true)
        case value
        when 'true'
          l(:general_text_Yes)
        when 'false'
          l(:general_text_No)
        else
          format_criteria_value_without_easy_extensions(criteria_options, value, html)
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'TimelogHelper', 'EasyPatch::TimelogHelperPatch'
