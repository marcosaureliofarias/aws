import gql from "graphql-tag";

const newAllocation = gql`
  mutation($attributes: JSON!) {
    easyGanttResource(attributes: $attributes) {
      easyGanttResource {
      id
      }
      errors {
        attribute
        fullMessages
      }
    }
  }
`;

export default newAllocation;
