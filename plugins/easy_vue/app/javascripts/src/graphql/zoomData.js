import gql from "graphql-tag";

const zoomQuery = gql`
  query($id: ID!) {
    easyMeeting(id: $id) {
      id
      meetingType {
        key
        value
      }
      availableMeetingTypes {
        key
        value
      }
    }
  }
`;

export { zoomQuery };
