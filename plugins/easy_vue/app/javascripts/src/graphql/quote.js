import gql from "graphql-tag";

const quoteQuery = gql`
  query($id: ID!) {
    easyPriceBookQuote(id: $id) {
        id
        name
        userlimit
        usermonths
        solution
        startDate
        currency
        subscriptionType
        dueDate
        easyCrmCase {
          id
        }
        brand {
          id
        }
      }
  }
`;

export { quoteQuery };
