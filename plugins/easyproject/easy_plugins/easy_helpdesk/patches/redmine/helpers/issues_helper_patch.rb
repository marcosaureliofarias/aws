module EasyHelpdesk
  module IssuesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :easy_issue_tabs, :easy_helpdesk

        def render_issue_easy_helpdesk_info(issue)
          s = ''
          unless issue.easy_helpdesk_mailbox_username.blank?
            s << l(:label_issue_bottom_from_easy_helpdesk, easy_helpdesk_mailbox_username: issue.easy_helpdesk_mailbox_username)
          end

          if issue.easy_helpdesk_sla_visible_for?(User.current) && issue.easy_helpdesk_project_sla
            if issue.easy_helpdesk_project_sla.title.present?
              s << "<br /><span>#{issue.easy_helpdesk_project_sla.title} </span>"
            end
            if issue.easy_response_date_time.present? && (response_info = render_issue_easy_helpdesk_sla_response_info(issue))
              s << '<br />'
              s << response_info
            end
            if issue.easy_due_date_time.present? && (resolve_info = render_issue_easy_helpdesk_sla_resolve_info(issue))
              s << '<br />'
              s << resolve_info
            end
          end

          s.html_safe
        end

        def render_issue_easy_helpdesk_sla_response_info(issue)
          return nil if issue.easy_response_date_time.nil?
          if issue.status == issue.default_status && !User.current.hide_sla_data?
            if Time.now < issue.easy_response_date_time
              response_info = l(:text_issue_easy_helpdesk_projects_sla_hours_to_response_before_time, time: format_time(issue.easy_response_date_time))
              span_class = ''
            else
              response_info =  l(:text_issue_easy_helpdesk_projects_sla_hours_to_response_after_time, time: format_time(issue.easy_response_date_time))
              span_class = 'overdue'
            end

            content_tag(:span, class: span_class) do
              if issue.easy_time_to_solve_paused?
                response_info.concat(' - ' + l(:title_sla_waiting_for_client))
              else
                response_info
              end
            end
          end
        end

        def render_issue_easy_helpdesk_sla_resolve_info(issue)
          return nil if issue.easy_due_date_time.nil?
          if !issue.status.is_closed? && !User.current.hide_sla_data?
            if Time.now < issue.easy_due_date_time
              resolve_info = l(:text_issue_easy_helpdesk_projects_sla_hours_to_solve_before_time, time: format_time(issue.easy_due_date_time))
              span_class = ''
            else
              resolve_info =  l(:text_issue_easy_helpdesk_projects_sla_hours_to_solve_after_time, time: format_time(issue.easy_due_date_time))
              span_class = 'overdue'
            end

            content_tag(:span, class: span_class) do
              if issue.easy_time_to_solve_paused?
                resolve_info.concat(' - ' + l(:title_sla_waiting_for_client))
              else
                resolve_info
              end
            end
          end
        end

      end
    end

    module InstanceMethods
      def easy_issue_tabs_with_easy_helpdesk(issue)
        tabs = easy_issue_tabs_without_easy_helpdesk(issue)
        if issue.display_easy_helpdesk_info?
          url = issue_render_tab_path(issue, tab: 'easy_sla_events')
          tabs << { name: 'easy_sla_events', label: l(:label_tab_sla_events), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
        end
        tabs
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyHelpdesk::IssuesHelperPatch'
