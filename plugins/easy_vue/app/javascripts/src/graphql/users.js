import gql from "graphql-tag";

const usersQuery = gql`
  {
    allUsers {
      id
      name
      avatarUrl
    }
  }
`;

export default usersQuery;
