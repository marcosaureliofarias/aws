import gql from "graphql-tag";

const duration = gql`
  mutation($id: ID, $attributes: JSON!, $changing: JSON!, $toBeSaved: Boolean!) {
    issueDuration(id: $id, attributes: $attributes, changing: $changing, toBeSaved: $toBeSaved) {
      issue {
        startDate
        dueDate
        duration
        availableDurationUnits {
          key
          value
        }
      }
      errors {
        attribute
        fullMessages
      }
    }
  }
`;

export default duration;