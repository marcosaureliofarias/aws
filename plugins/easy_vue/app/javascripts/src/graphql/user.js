import gql from "graphql-tag";

const userQuery = gql`
  query($id: ID!) {
    user(id: $id) {
      avatarUrl
      id
      name
    }
  }
`;

export default userQuery;
