import gql from "graphql-tag";

const quotePefillQuery = gql`
  query($id: ID!) {
    easyCrmCase(id: $id) {
        id
        currency
        activeQuote {
          id
          userlimit
          usermonths
          brand {
            id
          }
        }
      }
  }
`;

export { quotePefillQuery };
