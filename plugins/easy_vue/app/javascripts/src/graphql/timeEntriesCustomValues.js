import gql from "graphql-tag";

const timeEntriesCustomValuesQuery = gql`
  query($id: ID!, $activityId: Int) {
    issue(id: $id) {
      id
      timeEntriesCustomValues(activityId: $activityId) {
        customField {
          description
          easyGroup {
            name
            id
          }
          fieldFormat
          id
          internalName
          isRequired
          multiple
          name
          settings
          type
          formatStore
          defaultValue
        }
        possibleValues
        editable
        value
        formattedValue
      }
    }
  }
`;

export default timeEntriesCustomValuesQuery;
