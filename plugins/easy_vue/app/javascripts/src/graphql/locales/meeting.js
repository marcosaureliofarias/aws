import gql from "graphql-tag";
import { globalLocales, newEntities } from "./global";

const meetingLocales = gql`
  {
    allLocales(
      keys: [
        "field_all_day"
        "field_start_time"
        "field_end_time"
        "field_easy_room"
        "field_name"
        "field_priority"
        "field_place_name"
        "field_privacy"
        "label_invitations"
        "label_project"
        "field_author"
        "field_mails"
        "field_big_recurring"
        "button_easy_is_not_easy_repeating"
        "button_meeting_accept"
        "button_meeting_decline"
        "button_open_parent"
        "button_stay_here"
        "button_log_time"
        "button_manage_invitations"
        "label_easy_attendance_is_repeating"
        "label_meeting_email_settings"
        "label_email_notifications.right_now"
        "label_email_notifications.one_week_before"
        "label_easy_meeting_easy_resource_dont_allocate"
        "label_current_event"
        "label_current_and_following_events"
        "label_all_events"
        "label_delete_repeating_events"
        "label_easy_issue_easy_is_repeating"
        "title_easy_repeating_advanced_header"
        "label_easy_is_easy_repeating_period"
        "label_easy_issue_easy_repeating_endtype"
        "label_easy_issue_easy_repeating_period_daily"
        "label_easy_issue_easy_repeating_period_weekly"
        "label_easy_issue_easy_repeating_period_monthly"
        "label_easy_issue_easy_repeating_period_yearly"
        "label_easy_issue_easy_reccuring_daily_every"
        "label_easy_issue_easy_reccuring_recur_every"
        "label_easy_issue_easy_reccuring_daily_each"
        "label_easy_issue_easy_reccuring_daily_work"
        "label_easy_issue_easy_reccuring_recur_months"
        "label_easy_issue_easy_reccuring_recur_years"
        "label_easy_is_easy_repeating_endtype_date"
        "label_easy_issue_reccuring_monthly_orders.1"
        "label_easy_issue_reccuring_monthly_orders.2"
        "label_easy_issue_reccuring_monthly_orders.3"
        "label_easy_issue_reccuring_monthly_orders.4"
        "label_easy_issue_reccuring_monthly_orders.5"
        "label_easy_repeating_time_section_heading"
        "label_easy_issue_reccuring_after"
        "label_easy_issue_easy_reccuring_after_recurs"
        "prompt_easy_repeat_simple_repeat"
        "label_easy_is_easy_repeating_create_time"
        "label_easy_is_easy_repeating_time_hour"
        "hint_easy_repeating_repeat_hour_field"
        "label_easy_is_easy_repeating_create_now"
        "text_easy_repeating_reccuring_create_now"
        "label_easy_issue_easy_repeating_dont_create_now"
        "label_easy_issue_easy_repeating_create_now_all"
        "label_easy_issue_easy_repeating_create_now"
        "label_easy_is_easy_repeating_create_now_count_hint"
        "label_info_big_recurring_edit_parent"
        "button_check_availability"
        "label_resend_invitations"
        ${globalLocales}
        ${newEntities}
      ]
    ) {
      key
      translation
    }
  }
`;

export default meetingLocales;
