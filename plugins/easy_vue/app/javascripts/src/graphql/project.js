import gql from "graphql-tag";

export default function projectPrimaryQueryBuilder() {
  const x = `query($id: ID!) {
    project(id: $id) {
      id
      author {
        avatarUrl
        id
        name
      }
      name,
      id,
      createdOn
      descendants {
        name
        createdOn
        dueDate
        startDate
        description(formatted: true)
        id
      }
      description(formatted: true)
      dueDate
      startDate
      users {
        avatarUrl
        name
        id
      }
      totalEstimatedHours
      totalSpentHours
      journals{
        user{
          name
          id
          avatarUrl
        }
        createdOn
        details{
          asString
        }
      }
    }
  }`;
  const query = gql(x);
  return query;
}
