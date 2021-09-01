import gql from "graphql-tag";

const externalEventQuery = gql`
  query($id: ID!) {
    easyIcalendarEvent(id: $id) {
      dtstart
      dtend
      location
      summary
      organizer
      isPrivate
      easyIcalendar{
        id
        name
        message
        url
        status
        synchronizedAt
        user{
          id
          avatarUrl
          name
        }
        visibility
      }
    }
  }
`;

export { externalEventQuery };
