import gql from "graphql-tag";
import { globalLocales } from "./global";

const activityLocales = gql`
  {
    allLocales(
      keys: [
        "easy_scheduler.label_calendar_url_name",
        "field_synchronized_at",
        "easy_scheduler.label_ical_event",
        "field_place_name",
        "field_all_day",
        "label_date_from",
        "label_date_to",
        ${globalLocales}
      ]
    ) {
      key
      translation
    }
  }
`;

export default activityLocales;