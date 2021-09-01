import gql from "graphql-tag";

export default function taskListItemQuery(type, term) {
  const x = `
  query($id: ID!) {
    issue(id: $id) {
      id
      ${type}(term: ${term}) {
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
  }
`;
  const query = gql(x);
  return query;
}
