import gql from "graphql-tag";

const allocation = gql`
  mutation($id: ID!, $attributes: JSON!) {
    easyGanttResource(id: $id, attributes: $attributes) {
      easyGanttResource {
         custom
      date
      hours
      id
      issue{
        id
        subject
      }
      originalHours
      user{
        id
        name
      }
      endTime
      startTime
      }
      errors {
        attribute
        fullMessages
      }
    }
  }
`;

export default allocation;
