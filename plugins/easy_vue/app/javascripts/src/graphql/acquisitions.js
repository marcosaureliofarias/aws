import gql from "graphql-tag";

const acquisitionsQuery = gql`
  query($id: ID!) {
    easyCrmCase(id: $id) {
      id
      activeQuote {
        id
        name
        startDate
        dueDate
        usermonths
        solution
        userlimit
        price
        currency
        brand {
          id
          name
        }
      }
      easyWebApplication {
        easyWebApplicationPath
        url
        id
      }
    }
  }
`;

export { acquisitionsQuery };
