import gql from "graphql-tag";

export const meetingValidator = gql`
  mutation($attributes: JSON!) {
    easyMeetingValidator(attributes: $attributes) {
      errors {
        attribute
        fullMessages
      }
      easyMeeting {
        availablePrivacies {
          key
          value
        }
        easyZoomEnabled
      }
    }
  }
`;
