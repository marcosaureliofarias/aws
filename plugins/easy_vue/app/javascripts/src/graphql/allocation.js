import gql from "graphql-tag";

const allocationQuery = gql`
  query($id: ID!) {
    easyGanttResource(id: $id) {
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
  }
`;

export { allocationQuery };
