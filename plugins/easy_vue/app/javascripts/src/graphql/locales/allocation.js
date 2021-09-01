import gql from "graphql-tag";
import { globalLocales, newEntities } from "./global";

const allocationLocales = gql`
  {
    allLocales(
      keys: [
        "easy_scheduler.label_sales_allocation",
        "easy_scheduler.label_new_sales_allocation",
        "easy_scheduler.label_new_attendance",
        "easy_scheduler.label_meeting",
        "easy_scheduler.label_new_allocation",
        "field_issue",
        "label_date_from",
        "label_date_to",
        "label_date",
        ${globalLocales}
        ${newEntities}
      ]
    ) {
      key
      translation
    }
  }
`;

export default allocationLocales;
