import gql from "graphql-tag";

const attendanceInit = gql`
  mutation($id: ID, $attributes: JSON!) {
    easyAttendanceValidator(id: $id, attributes: $attributes) {
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
        range {
          key
          value
        }
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
        morning
        evening
        workingTime
        canEdit
        canEditUsers
      }
    }
  }
`;

export default attendanceInit;
