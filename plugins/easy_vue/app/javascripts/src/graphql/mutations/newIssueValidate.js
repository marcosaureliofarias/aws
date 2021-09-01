import gql from "graphql-tag";
export default function issueValidate() {
  const issueValidate = `
  mutation( $attributes: JSON! ) {
    issueValidator( attributes: $attributes ){
       issue{
       tracker{
        id
        name
       }
       status{
        id
        name
      }
      priority {
        id
        name
      }
      requiredAttributeNames
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
      errors {
        attribute,
          fullMessages
      }
      errors {
        attribute,
          fullMessages
      }
    }
  }
  `;
  const mutation = gql(issueValidate);
  return mutation;
};
