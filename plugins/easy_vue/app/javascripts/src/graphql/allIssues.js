import gql from "graphql-tag";

const allIssuesQuery = gql`
  query($filter: EasyIssueQueryFilter) {
    allIssues(filter: $filter) {
      id
      subject
      id
      easyLevel
      status {
        id
        isClosed
        name
      }
      assignedTo {
        id
        name
        avatarUrl
      }
      doneRatio
      priority {
        id
        easyColorScheme
        name
      }
    }
  }
`;

export default allIssuesQuery;
