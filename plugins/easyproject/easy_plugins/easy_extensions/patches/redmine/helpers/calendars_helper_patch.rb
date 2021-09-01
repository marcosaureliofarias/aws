module EasyPatch
  module CalendarsHelperPatch

    def self.included(base)
      base.class_eval do

        def render_easy_issue_query_form_buttons_bottom_on_issues_calendar(query, options)
          year  = options[:year] || Date.today.year
          month = options[:month] || Date.today.month
          s     = ''
          s << '<div id="calendar_listing" class="easy-calendar-listing-links next-prev-links easy-calendar-listing-links-with-inputs">'
          s << easy_link_to_previous_month(year, month, class: 'prev')
          s << label_tag('month', l(:label_month))
          s << select_month(month, { prefix: 'month', discard_type: true }, { class: 'inline' })
          s << label_tag('year', l(:label_year))
          s << select_year(year, { prefix: 'year', discard_type: true }, { class: 'inline' })
          s << easy_link_to_next_month(year, month, class: 'next')
          s << late_javascript_tag("$('#calendar_listing select').change(function() {window.location.search = $('#calendar_listing select').serialize()})")
          s << '</div>'
          s.html_safe
        end

        def easy_link_to_previous_month(year, month, options = {})
          target_year, target_month = month == 1 ? [year - 1, 12] : [year, month - 1]
          name                      = target_month == 12 ? "#{month_name(target_month)} #{target_year}" : "#{month_name(target_month)}"

          link_to_month(content_tag(:span, ("\xc2\xab " + name)), target_year, target_month, options)
        end

        def easy_link_to_next_month(year, month, options = {})
          target_year, target_month = (month == 12) ? [year + 1, 1] : [year, month + 1]
          name                      = target_month == 1 ? "#{month_name(target_month)} #{target_year}" : "#{month_name(target_month)}"

          link_to_month(content_tag(:span, (" \xc2\xbb" + name)), target_year, target_month, options)
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'CalendarsHelper', 'EasyPatch::CalendarsHelperPatch'
