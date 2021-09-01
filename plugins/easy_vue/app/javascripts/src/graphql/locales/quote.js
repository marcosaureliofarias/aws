import gql from "graphql-tag";
import { globalLocales, formModal } from "./global";

const quoteLocales = gql`
  {
    allLocales(
      keys: [
        "quote_form.new_quote_header"
        "quote_form.edit_quote_header"
        "quote_form.label_start_date"
        "quote_form.label_due_date"
        "quote_form.label_solution"
        "quote_form.label_name"
        "quote_form.label_brand"
        "quote_form.placeholder_brand"
        "quote_form.label_currency"
        "quote_form.placeholder_currency"
        "quote_form.label_subscription"
        "quote_form.placeholder_subscription"
        "quote_form.label_months"
        "quote_form.label_users"
        "quote_form.validation.name_required"
        "quote_form.validation.months_required"
        "quote_form.validation.users_required"
        "quote_form.validation.solution_required"
        "quote_form.validation.brand_required"
        "quote_form.validation.subscription_required"
        "quote_form.validation.currency_required"
        ${globalLocales}
        ${formModal}
      ]
    ) {
      key
      translation
    }
  }
`;

export default quoteLocales;
