import gql from "graphql-tag";

const activityQuery = gql`
  query($id: ID!) {
    easyEntityActivity(id: $id) {
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
  }
`;

export { activityQuery };
