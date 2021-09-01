import gql from "graphql-tag";
import { globalLocales, newEntities } from "./global";

const activityLocales = gql`
  {
    allLocales(
      keys: [
        "easy_scheduler.label_sales_activity",
        "easy_scheduler.label_new_sales_activity",
        "easy_scheduler.label_new_attendance",
        "easy_scheduler.label_meeting",
        "easy_scheduler.label_new_allocation",
        "field_type",
        "field_all_day",
        "field_easy_entity_activity_finished",
        "label_easy_contacts",
        "label_date_from",
        "label_date_to",
        "label_date",
        "button_show_details"
        ${globalLocales}
        ${newEntities}
      ]
    ) {
      key
      translation
    }
  }
`;

export default activityLocales;