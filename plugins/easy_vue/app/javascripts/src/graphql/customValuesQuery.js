import gql from "graphql-tag";

const timeEntriesQuery = gql`
  query($id: ID!) {
    issue(id: $id) {
      id
      customValues {
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

export default timeEntriesQuery;
