import gql from "graphql-tag";

const activity = gql`
  mutation($id: ID, $attributes: JSON, $attendees: JSON) {
    easyEntityActivity(id: $id, attributes: $attributes, attendees: $attendees) {
      easyEntityActivity {
        allDay
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
        category {
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
        contactAttendees {
          easyContactPath
          firstname
          id
          lastname
          name
        }
        availableTypes {
          key
          value
        }
        description
        endTime
        entityId
        entityType {
          key
          value
        }
        entityName
        id
        isFinished
        startTime
        userAttendees {
          avatarUrl
          id
          name
        }
      }
      errors {
        attribute,
        fullMessages
      }
    }
  }
`;

export default activity;
