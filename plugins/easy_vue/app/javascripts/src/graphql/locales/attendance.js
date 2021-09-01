import gql from "graphql-tag";
import { globalLocales, newEntities } from "./global";

const attendanceLocales = gql`
  {
    allLocales(
      keys: [
        "field_easy_attendance_activity",
        "easy_attendance.field_range",
        "easy_attendance.arrival",
        "field_approved_by",
        "field_approved_at",
        "easy_attendance.approval_status",
        "easy_attendance.departure",
        "field_at_work",
        "easy_attendance.approval_actions.2"
        "easy_attendance.approval_actions.3"
        "easy_attendance.attendance_overview"
        "easy_attendance.approval-1"
        "label_date_from"
        "label_date_to"
        ${globalLocales}
        ${newEntities}
      ]
    ) {
      key
      translation
    }
  }
`;

export default attendanceLocales;
