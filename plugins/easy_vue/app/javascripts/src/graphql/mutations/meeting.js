import gql from "graphql-tag";

const meeting = easyZoomEnabled => {
  const easyZoomData = `
      meetingType {
        key
        value
      }
      availableMeetingTypes {
        key
        value
      }
  `;
  return gql`
    mutation($id: ID!, $attributes: JSON!) {
      easyMeetingUpdate(easyMeetingId: $id, attributes: $attributes) {
        easyMeeting {
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
          ${easyZoomEnabled ? easyZoomData : ""}
        }
        errors
      }
    }
  `;
};

export default meeting;
