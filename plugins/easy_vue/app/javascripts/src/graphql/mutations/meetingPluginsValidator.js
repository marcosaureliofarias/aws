import gql from "graphql-tag";

export const meetingPluginsValidator = zoomEnabled => {
  const zoomData = `
      meetingType {
        key
        value
      }
      availableMeetingTypes {
        key
        value
      }`;
  return gql`
    mutation($attributes: JSON!) {
      easyMeetingValidator(attributes: $attributes) {
        errors {
          attribute
          fullMessages
        }
        easyMeeting {
          easyZoomEnabled
          ${zoomEnabled ? zoomData : ""}
        }
      }
    }
  `;
};
