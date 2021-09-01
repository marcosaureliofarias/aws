module EasyCalendar
  module AdvancedCalendars
    class EasyCrmCaseCalendar < EasyAdvancedCalendar
      def self.label; :label_easy_crm; end
      def self.permissions; :view_easy_crms; end

      def events(start_date, end_date)
        ecrm_events = EasyCrmCase.arel_table

        events = EasyCrmCase.active.
          where(easy_crm_case_status_id: EasyCrmCaseStatus.active.pluck(:id)).
          where(ecrm_events[:assigned_to_id].eq(User.current.id).or(ecrm_events[:external_assigned_to_id].eq(User.current.id))).
          where(ecrm_events[:next_action].not_eq(nil).or(ecrm_events[:contract_date].not_eq(nil))).
          where(
            (ecrm_events[:next_action].lteq(end_date).and(ecrm_events[:next_action].gteq(start_date))).
            or(ecrm_events[:contract_date].lteq(end_date).and(ecrm_events[:contract_date].gteq(start_date)))
          ).collect do |easy_crm_case|
            easy_crms = []
            if easy_crm_case.next_action
              next_action = easy_crm_case.next_action_in_zone
              easy_crms << {
                :id => "easy_crm_case-#{easy_crm_case.id}",
                :event_type => 'easy_crm_case_next_action',
                :title => easy_crm_case.name.to_s,
                :start => next_action.iso8601,
                :end => (next_action + 15.minutes).iso8601,
                :all_day => easy_crm_case.all_day,
                :color => '#f96d56',
                :border_color => '#f96d56',
                :url => @controller.easy_crm_case_path(easy_crm_case)
              }
            end
            easy_crms << {
              :id => "easy_crm_case-#{easy_crm_case.id}",
              :event_type => 'easy_crm_case_contract',
              :title => easy_crm_case.name.to_s,
              :start => easy_crm_case.contract_date.iso8601,
              :end => easy_crm_case.contract_date.iso8601,
              :color => '#a7c56b',
              :border_color => '#a7c56b',
              :url => @controller.easy_crm_case_path(easy_crm_case)
            } if easy_crm_case.contract_date
            easy_crms
          end
          events.flatten
      end

    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyCrmCaseCalendar)
