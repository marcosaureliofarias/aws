module EasyCalendar
  module AdvancedCalendars
    class VersionCalendar < EasyAdvancedCalendar
      def self.label; :label_version_plural; end
      def self.new_record_path; :new_easy_version_path; end
      def self.create_record_path; :versions_path; end
      def self.permissions; :view_issues; end

      def self.has_project_events?
        true
      end

      def events(start_date, end_date)
        collect_events(versions_from_range(start_date, end_date))
      end

      def project_events(start_date, end_date, project)
        collect_events(versions_from_range(start_date, end_date).where(:project_id => project.id))
      end

      def collect_events(events)
        events.to_a.collect do |version|
          effective_date = version.effective_date
          {
            :id => "version-#{version.id}",
            :event_type => 'version',
            :title => version.to_s,
            :start => effective_date.iso8601,
            :end => effective_date.iso8601,
            :color => '#f5f5f5',
            :border_color => '#e8c6c5',
            :url => @controller.version_path(version),
            :editable => false,
            :class_name => 'easy-version'
          }
        end
      end

      def versions_from_range(start_date, end_date)
        Version.open.visible.where(effective_date: start_date..end_date)
      end

    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::VersionCalendar)
