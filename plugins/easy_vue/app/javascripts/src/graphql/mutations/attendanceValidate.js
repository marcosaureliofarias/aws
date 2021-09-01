import gql from "graphql-tag";

const attendanceValidate = gql`
  mutation($userIds: [ID!], $attributes: JSON!) {
    easyAttendanceValidator(userIds: $userIds, attributes: $attributes) {
      easyAttendance {
        allowedActivities{
          name
          internalName
          systemActivity
          position
          isDefault
          approvalRequired
          atWork
          colorSchema
          createdAt
          id
        }
        allowedRanges{
          key
          value
        }
        arrival
        departure
        workingTime
        evening
        morning
        description
        canEdit
        canEditUsers
        easyAttendanceActivity {
          name
          internalName
          systemActivity
          position
          isDefault
          approvalRequired
          atWork
          colorSchema
          createdAt
          id
        }
        range {
          key
          value
        }
      }
      errors {
        attribute,
        fullMessages,
        user {
          id
          name
          avatarUrl
        }
      }
    }
  }
`;

export default attendanceValidate;
