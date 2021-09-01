import gql from "graphql-tag";

const timeEntriesQuery = gql`
  query($id: ID!) {
    issue(id: $id) {
      id
      timeEntries {
        editable
        deletable
        spentOn
        easyIsBillable
        user {
          name
          id
          avatarUrl
        }
        comments
        hours
        id
        issue {
          id
          subject
        }
        project {
          id
          name
        }
      }
    }
  }
`;

export default timeEntriesQuery;
