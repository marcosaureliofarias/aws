module EasyCalendar
  module AdvancedCalendars
    class IssueCalendar < EasyAdvancedCalendar
      def self.label; :label_issue_plural; end
      def self.new_record_path; :new_issue_path; end
      def self.create_record_path; :issues_path; end
      def self.permissions; :view_issues; end

      def self.has_project_events?
        true
      end

      def events(start_date, end_date)
        collect_events(issues_from_range(start_date, end_date))
      end

      def project_events(start_date, end_date, project)
        collect_events(issues_from_range(start_date, end_date).
          where(:project_id => project.id))
      end

      def collect_events(events)
        events.to_a.collect do |issue|
          {
            :id => "issue-#{issue.id}",
            :event_type => 'issue',
            :title => issue.to_s,
            :start => issue.start_date.iso8601,
            :end => issue.due_date.iso8601,
            :color => '#f5e7e6',
            :border_color => '#e8c6c5',
            :url => @controller.issue_path(issue),
            :editable => false,
            :project_name => issue.project.family_name.to_s
          }
        end
      end

      def issues_from_range(start_date, end_date)
        issues = Issue.arel_table
        Issue.open.visible.
          where(issues[:assigned_to_id].eq(User.current.id)).
          where(issues[:start_date].not_eq(nil)).
          where(issues[:due_date].not_eq(nil)).
          where(issues[:start_date].lteq(end_date)).
          where(issues[:due_date].gteq(start_date))
      end
    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::IssueCalendar)
