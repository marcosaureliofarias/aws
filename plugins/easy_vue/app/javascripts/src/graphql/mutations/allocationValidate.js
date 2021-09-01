import gql from "graphql-tag";

const allocationValidate = gql`
    mutation($attributes: JSON!) {
    easyGanttResourceValidator(attributes: $attributes) {
      errors {
        attribute
        fullMessages
      }
    }
}`;

export default allocationValidate;
