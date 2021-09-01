import gql from "graphql-tag";

export default function taskListItemQuery(type) {
  const taskContent = `
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
  `;
  let taskListStructure = `${taskContent}`;
  if (type === "relations") {
    taskListStructure = `
      id
      relationName(issueId: $id)
      otherIssue(issueId: $id) {
        ${ taskContent }
      }
    `;
  }
  const x = `
    query($id: ID!) {
      issue(id: $id) {
        id
        ${type} {
          ${taskListStructure}
        }
      }
    }
  `;
  const query = gql(x);
  return query;
}
