import gql from "graphql-tag";

const quoteValidator = gql`
mutation($attributes: JSON!) {
  easyPriceBookQuoteValidator(attributes: $attributes){
    easyPriceBookQuote {
      availableBrands {
        id
        name
      }
      availableCurrencies {
        name
        isoCode
      }
      availableSolutions {
        key
        value
      }
      availableSubscriptionTypes {
        key
        value
      }
    }
  }
}
`;

export default quoteValidator;
