import gql from "graphql-tag";

const attendance = gql`
  mutation($id: ID!, $attributes: JSON!) {
    easyAttendanceUpdate(easyAttendanceId: $id, attributes: $attributes) {
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
        approvalStatus {
          key
          value
        }
        approvedBy {
          avatarUrl
          id
          name
        }
        canApprove
        canEdit
        canEditUsers
        canRequestCancel
        canDelete
        needApprove
        approvedAt
        arrival
        departure
        createdAt
        workingTime
        evening
        morning
        description
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
        editedBy {
          avatarUrl
          id
          name
        }
        editedWhen
        hours
        id
        locked
        previousApprovalStatus
        range {
          key
          value
        }
        updatedAt
        user {
          avatarUrl
          id
          name
        }
        journals {
          createdOn
          details {
            asString
            id
            value
          }
          id
          notes
          privateNotes
          user {
            avatarUrl
            id
            name
          }
        }
      }
      errors {
        attribute,
        fullMessages
      }
    }
  }
`;

export default attendance;
