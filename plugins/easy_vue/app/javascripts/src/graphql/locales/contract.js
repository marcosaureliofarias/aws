import gql from "graphql-tag";
import { globalLocales } from "./global";

const contractModalLocales = gql`
  {
    allLocales(
      keys: [
        "easy_contracts.field_currency"
        "easy_contracts.field_custom_repository"
        "easy_contracts.field_discount"
        "easy_contracts.field_implementation_hours"
        "easy_contracts.field_license_key"
        "easy_contracts.field_total_price"
        "easy_contracts.field_product"
        "easy_contracts.field_solution"
        "easy_contracts.field_user_count"
        "easy_contracts.field_user_limit"
        "easy_contracts.field_easy_application"
        "easy_contracts.field_created_at"
        "easy_contracts.field_updated_at"
        "easy_contracts.field_start_date"
        "easy_contracts.field_end_date"
        "label_easy_contact_easy_crm_cases"
        "label_easy_invoice_plural"
        ${globalLocales}
      ]
    ) {
      key
      translation
    }
  }
`;

export default contractModalLocales;
