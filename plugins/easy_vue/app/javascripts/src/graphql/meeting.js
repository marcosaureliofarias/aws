import gql from "graphql-tag";

const meetingQuery = gql`
  query($id: ID!) {
    easyMeeting(id: $id) {
      allDay
      author {
        avatarUrl
        id
        name
      }
      editable
      bigRecurring
      createdAt
      description
      easyIsRepeating
      easyRepeatSettings
      easyRepeatParent {
        id
        name
        editable
        visible
        uid
      }
      easyInvitations {
        accepted
        alarms
        user {
          avatarUrl
          id
          name
        }
      }
      easyRoom {
        id
        capacity
        name
      }
      endTime
      id
      mails
      name
      placeName
      priority {
        key
        value
      }
      privacy {
        key
        value
      }
      availablePrivacies {
        key
        value
      }
      availablePriorities {
        key
        value
      }
      emailNotifications {
        key
        value
      }
      availableEmailNotifications {
        key
        value
      }
      startTime
      uid
      updatedAt
      project {
        id
        name
        description
      }
      easyZoomEnabled
    }
  }
`;

export { meetingQuery };
