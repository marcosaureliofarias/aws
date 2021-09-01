import gql from "graphql-tag";

const customField = gql`
  mutation(
    $entityId: ID!
    $entityType: String!
    $customFieldId: ID!
    $value: JSON!
  ) {
    customValueChange(
      entityId: $entityId
      entityType: $entityType
      customFieldId: $customFieldId
      value: $value
    ) {
      customValue {
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
      errors
    }
  }
`;

export default customField;
