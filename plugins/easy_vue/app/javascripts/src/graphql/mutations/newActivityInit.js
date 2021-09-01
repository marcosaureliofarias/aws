import gql from "graphql-tag";

const activityInit = gql`
  mutation($id: ID, $attributes: JSON!) {
    easyEntityActivityValidator(id: $id, attributes: $attributes) {
      easyEntityActivity {
        categories {
          active
          easyColorScheme
          easyExternalId
          id
          internalName
          isDefault
          name
          position
          type
        }
        availableTypes {
          key
          value
        }
      }
    }
  }
`;

export default activityInit;
