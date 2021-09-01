import gql from "graphql-tag";
import { globalLocales, formModal } from "./global";

const acquisitionsLocales = gql`
  {
    allLocales(
      keys: [
        "acquisition.header"
        "acquisition.label_start_date"
        "acquisition.label_due_date"
        "acquisition.label_selected_ewa"
        "acquisition.label_select_ewa"
        "acquisition.placeholder_select_ewa"
        "acquisition.validation.start_date_required"
        "acquisition.validation.due_date_required"
        "acquisition.validation.ewa_required"
        "acquisition.summary.name_title"
        "acquisition.summary.price_title"
        "acquisition.summary.months_title"
        "acquisition.summary.users_title"
        "acquisition.summary.solution_title"
        "acquisition.summary.brand_title"
        "acquisition.label_new_ewa_button"
        "acquisition.no_ewa_instances_message"
        ${globalLocales}
        ${formModal}
      ]
    ) {
      key
      translation
    }
  }
`;

export default acquisitionsLocales;
