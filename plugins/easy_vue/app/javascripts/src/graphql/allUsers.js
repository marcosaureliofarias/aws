import gql from "graphql-tag";

const allUsersQuery = gql`
  query($filter: EasyUserQueryFilter) {
    allUsers(filter: $filter, limit: 300) {
      avatarUrl
      id
      name
    }
  }
`;

export default allUsersQuery;
